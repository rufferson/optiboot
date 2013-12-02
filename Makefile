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

AVRDUDE=$(AVR_TOOLCHAIN_ROOT)/avrdude64 -C$(AVR_TOOLCHAIN_ROOT)/avrdude.conf -v -p$(TARGET) -P$(PGPORT)

# gcc
OBJCOPY = $(GCC_ROOT)/avr-objcopy
OBJDUMP = $(GCC_ROOT)/avr-objdump
SIZE    = $(GCC_ROOT)/avr-size
CC      = $(GCC_ROOT)/avr-gcc
AS      = $(GCC_ROOT)/avr-as

TARGET  = attiny85
MCU_TARGET = $(TARGET)
BAUD_RATE = 9600

override CFLAGS  = -g -Wall $(OPTIMIZE) -mmcu=$(MCU_TARGET) $(DEFS)
override LDFLAGS = -m$(TARGET) $(LDSECTIONS) -nostartfiles -nostdlib -Wl,-bihex
OPTIMIZE = -Os -fno-inline-small-functions -fno-split-wide-types -mshort-calls

PROGRAM  = optiboot.t85

OBJ      = $(PROGRAM).o
DEFS	 = -DBOOT_START=$(BOOT_START) -DRAMSTART=$(RAM_START) -DWDT_VECT=$(WDT_VECT) -DF_CPU=$(AVR_FREQ) -DBAUD_RATE=$(BAUD_RATE)

.PHONY: attiny85

attiny85: TARGET = attiny85
attiny85: AVR_FREQ   = 8000000
attiny85: FUSES		 = -e -Uefuse:w:0xFE:m -Uhfuse:w:0xD7:m -Ulfuse:w:0xE2:m
#attiny85: BOOT_START = 0x1DE0
attiny85: BOOT_START = 0x1E00
attiny85: RAM_START  = 0x0060
attiny85: WDT_VECT   = 0x0C
attiny85: CFLAGS    += '-DLED_START_FLASHES=80' '-DSOFT_UART' '-DVIRTUAL_BOOT_PARTITION'
attiny85: CFLAGS	+= -Wa,--gstabs -Wa,-alcms=$(PROGRAM).lst -Wa,-D -Wa,--warn
attiny85: LDSECTIONS = -Wl,--section-start=.text=$(BOOT_START) -Wl,--section-start=.version=0x1ffe
attiny85: $(PROGRAM).hex
attiny85: $(PROGRAM).lst

install: $(PROGRAM).hex
	cp $^ ~/sketchbook/hardware/tiny/bootloaders/optiboot/optiboot_attiny85.hex

upload: $(PROGRAM).hex
	$(AVRDUDE) -c$(PRGMER) -b$(PGRATE) $(FUSES)
	$(AVRDUDE) -c$(PRGMER) -b$(PGRATE) -Uflash:w:$(PROGRAM).hex:i

test: $(TARGET)
	$(AVRDUDE) -carduino -b$(BAUD_RATE) -n -Uflash:r:dump.hex:i

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
