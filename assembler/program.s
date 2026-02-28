# Minimal RV32I sample for current CPU MVP
# addi -> sw -> lw -> beq (skip) -> addi -> addi

addi x1, x0, 5
sw x1, 0(x0)
lw x2, 0(x0)
beq x1, x2, done
addi x3, x0, 1
done:
addi x3, x0, 9
