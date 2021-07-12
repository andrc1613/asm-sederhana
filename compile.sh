nasm -f elf jankenpon.asm
ld -m elf_i386 -s -o jankenpon jankenpon.o