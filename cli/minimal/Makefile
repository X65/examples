# **************************************************************************************
#
#									Very minimal makefile.
#
# **************************************************************************************

#
#		Path / Name of emulator.
#
EMULATOR = emu_linux_x64
#
#		64tass optios.
#
ASMOPTS = -b -w -x

#
#		Assemble the source
#
assemble:
	64tass test.asm $(ASMOPTS) -otest.xex -Ltest.lst
#
#		Run program without break.
#
run: assemble
	$(EMULATOR) -q file=test.xex	

#
#		Run program and break on 65816 NOP ($EA)
#
runbrk: assemble
	$(EMULATOR) -q file=test.xex break=EA
