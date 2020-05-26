USEGNU=gmake $*
all:
	@$(USEGNU) make_invoke_alias=make
.DEFAULT:
	@$(USEGNU) make_invoke_alias=make
