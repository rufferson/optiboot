# vim: set ts=4 noet:
AVR_TOOLCHAIN_ROOT = /opt/data/ar/arduino-1.0.5/hardware/tools
GCC_ROOT = $(AVR_TOOLCHAIN_ROOT)/avr/bin

# avrdude params
#PRGMER=arduino
#PGRATE=9600
# To flash
PRGMER=stk500v1
PGPORT=/dev/ttyUSB0
PGRATE=19200
#

AVRDUDE=$(AVR_TOOLCHAIN_ROOT)/avrdude64 -C$(AVR_TOOLCHAIN_ROOT)/avrdude.conf -v -p$(TARGET) -c$(PRGMER) -P$(PGPORT) -b$(PGRATE)

# gcc
OBJCOPY = $(GCC_ROOT)/avr-objcopy
OBJDUMP = $(GCC_ROOT)/avr-objdump
SIZE    = $(GCC_ROOT)/avr-size
CC      = $(GCC_ROOT)/avr-gcc
AS      = $(GCC_ROOT)/avr-as

TARGET  = attiny85
MCU_TARGET = $(TARGET)

override CFLAGS  = -g -Wall $(OPTIMIZE) -mmcu=$(MCU_TARGET) $(DEFS)
override LDFLAGS = -m$(TARGET) $(LDSECTIONS) -nostartfiles -nostdlib -Wl,-bihex
OPTIMIZE = -Os -fno-inline-small-functions -fno-split-wide-types -mshort-calls

PROGRAM  = optiboot.t85

OBJ      = $(PROGRAM).o
DEFS	 = -DBOOT_START=$(BOOT_START) -DRAMSTART=$(RAM_START) -DWDT_VECT=$(WDT_VECT) -DF_CPU=$(AVR_FREQ) -DBAUD_RATE=$(BAUD_RATE)

.PHONY: attiny85

attiny85: TARGET = attiny85
attiny85: AVR_FREQ   = 8000000
attiny85: BAUD_RATE  = 9600
attiny85: BOOT_START = 0x1DE0
attiny85: RAM_START  = 0x0060
attiny85: WDT_VECT   = 0x0C
attiny85: CFLAGS    += '-DLED_START_FLASHES=80' '-DSOFT_UART' '-DVIRTUAL_BOOT_PARTITION'
attiny85: CFLAGS	+= -Wa,--gstabs -Wa,-alhs=$(PROGRAM).lst
attiny85: LDSECTIONS = -Wl,--section-start=.text=$(BOOT_START) -Wl,--section-start=.version=0x1ffe
attiny85: $(PROGRAM).hex
attiny85: $(PROGRAM).lst

install: $(PROGRAM).hex
	cp $^ ~/sketchbook/hardware/tiny/bootloaders/optiboot/optiboot_attiny85.hex

upload: $(PROGRAM).hex
	$(AVRDUDE) -Uflash:w:$(PROGRAM).hex:i

%.o: %.S
	$(CC) $(CFLAGS) -c -o $@ $<

%.elf: %.o
	$(CC) $(LDFLAGS) -o $@ $^
	$(SIZE) $@

%.hex: %.elf
	$(OBJCOPY) -j .text -j .data -j .version --set-section-flags .version=alloc,load -O ihex $< $@

#%.lst: %.elf
#	$(OBJDUMP) -h -S $< > $@

clean:
	rm -rf *.o *.elf *.lst *.map *.sym *.lss *.eep *.srec *.bin *.hex
