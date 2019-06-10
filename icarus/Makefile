# Makefile for Icarus Verilog simulation
# 02-11-2019 E. Brombaugh

# sources
SOURCES = 	tb_vga.v ../src/vga.v ../src/rom_cg_2kB.v ../src/vram_32kb.v
        
# top level
TOP = tb_vga
			
# Executables
VLOG = iverilog
WAVE = gtkwave
TECH_LIB = /usr/local/share/yosys/ice40/cells_sim.v

# targets
all: $(TOP).vcd
			
wave: $(TOP).vcd $(TOP).gtkw
	$(WAVE) $(TOP).gtkw
	
$(TOP).vcd: $(TOP)
	./$(TOP)

$(TOP): $(SOURCES)
	$(VLOG) -D icarus -l $(TECH_LIB) -o $(TOP) $(SOURCES)
	
clean:
	rm -rf a.out *.obj $(RPT) $(TOP) $(TOP).vcd
	
