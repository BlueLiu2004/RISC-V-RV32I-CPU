from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass


OPCODES = {
	"addi": 0x13,
	"lw": 0x03,
	"sw": 0x23,
	"beq": 0x63,
	"jal": 0x6F,
	"jalr": 0x67,
}

FUNCT3 = {
	"addi": 0b000,
	"lw": 0b010,
	"sw": 0b010,
	"beq": 0b000,
	"jalr": 0b000,
}

LABEL_RE = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*)\s*:\s*(.*)$")
MEM_OPERAND_RE = re.compile(r"^(.+)\((x(?:[0-9]|[12][0-9]|3[01]))\)$")


@dataclass
class AsmLine:
	line_no: int
	text: str


class AssemblerError(Exception):
	pass


def parse_register(token: str, line_no: int) -> int:
	token = token.strip().lower()
	if not token.startswith("x"):
		raise AssemblerError(f"L{line_no}: 暫存器格式錯誤: {token}")
	try:
		idx = int(token[1:])
	except ValueError as exc:
		raise AssemblerError(f"L{line_no}: 暫存器格式錯誤: {token}") from exc
	if not (0 <= idx <= 31):
		raise AssemblerError(f"L{line_no}: 暫存器超出範圍: {token}")
	return idx


def parse_int(token: str, line_no: int) -> int:
	token = token.strip()
	try:
		return int(token, 0)
	except ValueError as exc:
		raise AssemblerError(f"L{line_no}: 立即數格式錯誤: {token}") from exc


def check_signed_range(value: int, bits: int, line_no: int, what: str) -> None:
	lo = -(1 << (bits - 1))
	hi = (1 << (bits - 1)) - 1
	if not (lo <= value <= hi):
		raise AssemblerError(f"L{line_no}: {what} 超出 {bits}-bit signed 範圍: {value}")


def encode_i(opcode: int, funct3: int, rd: int, rs1: int, imm: int, line_no: int, what: str) -> int:
	check_signed_range(imm, 12, line_no, what)
	imm12 = imm & 0xFFF
	return (imm12 << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode


def encode_s(opcode: int, funct3: int, rs1: int, rs2: int, imm: int, line_no: int) -> int:
	check_signed_range(imm, 12, line_no, "S-type immediate")
	imm12 = imm & 0xFFF
	imm11_5 = (imm12 >> 5) & 0x7F
	imm4_0 = imm12 & 0x1F
	return (
		(imm11_5 << 25)
		| (rs2 << 20)
		| (rs1 << 15)
		| (funct3 << 12)
		| (imm4_0 << 7)
		| opcode
	)


def encode_b(opcode: int, funct3: int, rs1: int, rs2: int, offset: int, line_no: int) -> int:
	if offset % 2 != 0:
		raise AssemblerError(f"L{line_no}: B-type offset 必須 2-byte 對齊: {offset}")
	check_signed_range(offset, 13, line_no, "B-type offset")
	imm13 = offset & 0x1FFF
	imm12 = (imm13 >> 12) & 0x1
	imm10_5 = (imm13 >> 5) & 0x3F
	imm4_1 = (imm13 >> 1) & 0xF
	imm11 = (imm13 >> 11) & 0x1
	return (
		(imm12 << 31)
		| (imm10_5 << 25)
		| (rs2 << 20)
		| (rs1 << 15)
		| (funct3 << 12)
		| (imm4_1 << 8)
		| (imm11 << 7)
		| opcode
	)


def encode_j(opcode: int, rd: int, offset: int, line_no: int) -> int:
	if offset % 2 != 0:
		raise AssemblerError(f"L{line_no}: J-type offset 必須 2-byte 對齊: {offset}")
	check_signed_range(offset, 21, line_no, "J-type offset")
	imm21 = offset & 0x1FFFFF
	imm20 = (imm21 >> 20) & 0x1
	imm10_1 = (imm21 >> 1) & 0x3FF
	imm11 = (imm21 >> 11) & 0x1
	imm19_12 = (imm21 >> 12) & 0xFF
	return (
		(imm20 << 31)
		| (imm10_1 << 21)
		| (imm11 << 20)
		| (imm19_12 << 12)
		| (rd << 7)
		| opcode
	)


def strip_comment(line: str) -> str:
	for marker in ("#", "//"):
		idx = line.find(marker)
		if idx != -1:
			line = line[:idx]
	return line.strip()


def split_mnemonic_operands(text: str, line_no: int) -> tuple[str, list[str]]:
	parts = text.split(None, 1)
	if not parts:
		raise AssemblerError(f"L{line_no}: 空指令")
	mnemonic = parts[0].lower()
	operands = []
	if len(parts) > 1:
		operands = [x.strip() for x in parts[1].split(",") if x.strip()]
	return mnemonic, operands


def parse_lines(src: str) -> list[AsmLine]:
	out: list[AsmLine] = []
	for line_no, raw in enumerate(src.splitlines(), start=1):
		text = strip_comment(raw)
		if text:
			out.append(AsmLine(line_no, text))
	return out


def first_pass(lines: list[AsmLine]) -> tuple[dict[str, int], list[AsmLine]]:
	labels: dict[str, int] = {}
	instructions: list[AsmLine] = []
	pc = 0

	for entry in lines:
		text = entry.text
		while True:
			match = LABEL_RE.match(text)
			if not match:
				break
			label = match.group(1)
			text = match.group(2).strip()
			if label in labels:
				raise AssemblerError(f"L{entry.line_no}: 重複 label: {label}")
			labels[label] = pc
		if text:
			instructions.append(AsmLine(entry.line_no, text))
			pc += 4

	return labels, instructions


def resolve_target(token: str, labels: dict[str, int], pc: int, line_no: int) -> int:
	token = token.strip()
	if token in labels:
		return labels[token] - pc
	return parse_int(token, line_no)


def parse_mem_operand(token: str, line_no: int) -> tuple[int, int]:
	match = MEM_OPERAND_RE.match(token.replace(" ", ""))
	if not match:
		raise AssemblerError(f"L{line_no}: 記憶體運算元格式錯誤，預期 imm(rs1): {token}")
	imm = parse_int(match.group(1), line_no)
	rs1 = parse_register(match.group(2), line_no)
	return imm, rs1


def assemble_instruction(text: str, line_no: int, labels: dict[str, int], pc: int) -> int:
	mnemonic, ops = split_mnemonic_operands(text, line_no)

	if mnemonic == "addi":
		if len(ops) != 3:
			raise AssemblerError(f"L{line_no}: addi 格式應為: addi rd, rs1, imm")
		rd = parse_register(ops[0], line_no)
		rs1 = parse_register(ops[1], line_no)
		imm = parse_int(ops[2], line_no)
		return encode_i(OPCODES[mnemonic], FUNCT3[mnemonic], rd, rs1, imm, line_no, "addi immediate")

	if mnemonic == "lw":
		if len(ops) != 2:
			raise AssemblerError(f"L{line_no}: lw 格式應為: lw rd, imm(rs1)")
		rd = parse_register(ops[0], line_no)
		imm, rs1 = parse_mem_operand(ops[1], line_no)
		return encode_i(OPCODES[mnemonic], FUNCT3[mnemonic], rd, rs1, imm, line_no, "lw immediate")

	if mnemonic == "sw":
		if len(ops) != 2:
			raise AssemblerError(f"L{line_no}: sw 格式應為: sw rs2, imm(rs1)")
		rs2 = parse_register(ops[0], line_no)
		imm, rs1 = parse_mem_operand(ops[1], line_no)
		return encode_s(OPCODES[mnemonic], FUNCT3[mnemonic], rs1, rs2, imm, line_no)

	if mnemonic == "beq":
		if len(ops) != 3:
			raise AssemblerError(f"L{line_no}: beq 格式應為: beq rs1, rs2, target")
		rs1 = parse_register(ops[0], line_no)
		rs2 = parse_register(ops[1], line_no)
		offset = resolve_target(ops[2], labels, pc, line_no)
		return encode_b(OPCODES[mnemonic], FUNCT3[mnemonic], rs1, rs2, offset, line_no)

	if mnemonic == "jal":
		if len(ops) == 1:
			rd = 1
			offset = resolve_target(ops[0], labels, pc, line_no)
		elif len(ops) == 2:
			rd = parse_register(ops[0], line_no)
			offset = resolve_target(ops[1], labels, pc, line_no)
		else:
			raise AssemblerError(f"L{line_no}: jal 格式應為: jal rd, target 或 jal target")
		return encode_j(OPCODES[mnemonic], rd, offset, line_no)

	if mnemonic == "jalr":
		if len(ops) != 2:
			raise AssemblerError(f"L{line_no}: jalr 格式應為: jalr rd, imm(rs1)")
		rd = parse_register(ops[0], line_no)
		imm, rs1 = parse_mem_operand(ops[1], line_no)
		return encode_i(OPCODES[mnemonic], FUNCT3[mnemonic], rd, rs1, imm, line_no, "jalr immediate")

	raise AssemblerError(f"L{line_no}: 不支援的指令: {mnemonic}")


def assemble(source: str) -> list[tuple[int, AsmLine]]:
	lines = parse_lines(source)
	labels, instructions = first_pass(lines)

	output: list[tuple[int, AsmLine]] = []
	pc = 0
	for ins in instructions:
		code = assemble_instruction(ins.text, ins.line_no, labels, pc)
		output.append((code, ins))
		pc += 4
	return output


def format_output(items: list[tuple[int, AsmLine]]) -> str:
	rows: list[str] = []
	for idx, (code, _) in enumerate(items):
		rows.append(f"rom[{idx}] = 32'h{code:08x};")
	return "\n".join(rows) + ("\n" if rows else "")


def main() -> int:
	parser = argparse.ArgumentParser(description="Mini RV32I assembler (addi/lw/sw/beq/jal/jalr)")
	parser.add_argument("input", help="輸入組語檔案，例如 program.s")
	parser.add_argument("-o", "--output", help="輸出檔案（省略則印到 stdout）")
	args = parser.parse_args()

	try:
		with open(args.input, "r", encoding="utf-8") as fin:
			source = fin.read()
		items = assemble(source)
		rendered = format_output(items)

		if args.output:
			with open(args.output, "w", encoding="utf-8") as fout:
				fout.write(rendered)
		else:
			sys.stdout.write(rendered)

		sys.stderr.write(f"Assembled {len(items)} instruction(s).\n")
		return 0
	except AssemblerError as exc:
		sys.stderr.write(f"Assembler error: {exc}\n")
		return 2
	except OSError as exc:
		sys.stderr.write(f"I/O error: {exc}\n")
		return 1


if __name__ == "__main__":
	raise SystemExit(main())
