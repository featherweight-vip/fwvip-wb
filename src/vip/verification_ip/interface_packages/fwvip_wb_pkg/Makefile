# fwvip_wb interface packages source
# pragma uvmf custom additional begin
# pragma uvmf custom additional end

fwvip_wb_PKG         ?= \
	+incdir+$(UVMF_VIP_LIBRARY_HOME)/interface_packages/fwvip_wb_pkg \
	-F $(UVMF_VIP_LIBRARY_HOME)/interface_packages/fwvip_wb_pkg/fwvip_wb_filelist_hvl.f 

fwvip_wb_PKG_HDL         ?= \
	+incdir+$(UVMF_VIP_LIBRARY_HOME)/interface_packages/fwvip_wb_pkg \
	-F $(UVMF_VIP_LIBRARY_HOME)/interface_packages/fwvip_wb_pkg/fwvip_wb_filelist_hdl.f 

fwvip_wb_PKG_XRTL         ?= \
	+incdir+$(UVMF_VIP_LIBRARY_HOME)/interface_packages/fwvip_wb_pkg \
	-F $(UVMF_VIP_LIBRARY_HOME)/interface_packages/fwvip_wb_pkg/fwvip_wb_filelist_xrtl.f 

COMP_fwvip_wb_PKG_TGT_0 = q_comp_fwvip_wb_pkg
COMP_fwvip_wb_PKG_TGT_1 = v_comp_fwvip_wb_pkg
COMP_fwvip_wb_PKG_TGT = $(COMP_fwvip_wb_PKG_TGT_$(USE_VELOCE))

comp_fwvip_wb_pkg: $(COMP_fwvip_wb_PKG_TGT) 

q_comp_fwvip_wb_pkg:
	$(HDL_COMP_CMD) $(fwvip_wb_PKG_HDL)
	$(HVL_COMP_CMD) $(fwvip_wb_PKG)
	$(HDL_COMP_CMD) $(fwvip_wb_PKG_XRTL) 

v_comp_fwvip_wb_pkg:
	$(HVL_COMP_CMD) $(fwvip_wb_PKG_HDL)
	$(HVL_COMP_CMD) $(fwvip_wb_PKG)
	$(VELANALYZE_CMD) $(fwvip_wb_PKG_HDL) 
	$(VELANALYZE_HVL_CMD) $(fwvip_wb_PKG) 
	$(HDL_COMP_CMD) $(fwvip_wb_PKG_XRTL)

ifeq ($(MTI_VCO_MODE),64)
  GCC_COMP_ARCH = -m64
else
  GCC_COMP_ARCH = -m32
endif

export fwvip_wb_IF_DPI_SRC ?= $(UVMF_VIP_LIBRARY_HOME)/interface_packages/fwvip_wb_pkg/dpi

C_FILE_COMPILE_LIST_fwvip_wb_pkg	?= \

O_FILE_COMPILE_LIST_fwvip_wb_pkg ?= $(notdir $(C_FILE_COMPILE_LIST_fwvip_wb_pkg:.c=.o))

GCC_COMP_ARGS_fwvip_wb_pkg	+= -I$(fwvip_wb_IF_DPI_SRC) \
	-fPIC 

GCC_COMP_ARGS_fwvip_wb_pkg	+= $(fwvip_wb_IF_GCC_COMP_ARGUMENTS)

GCC_LINK_ARGS_fwvip_wb_pkg	+= \
	 \
 	-o .so

comp_fwvip_wb_pkg_c_files:
	@echo "--------------------------------"
	@echo "Compiling Interface C source"
	@echo "--------------------------------"
	gcc $(GCC_COMP_ARCH) $(GCC_COMP_ARGS_fwvip_wb_pkg) $(C_FILE_COMPILE_LIST_fwvip_wb_pkg)
	@echo "--------------------------------"
	@echo "Linking Interface C objects into a shared object"
	@echo "--------------------------------"
	gcc $(GCC_COMP_ARCH) $(GCC_LINK_ARGS_fwvip_wb_pkg) $(O_FILE_COMPILE_LIST_fwvip_wb_pkg)
	@echo "--------------------------------"

