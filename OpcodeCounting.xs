#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <JavaScript.h>

#define PJS_ERROR_OPCODELILMIT_EXCEEDED "JavaScript::Error::OpcodeLimitExceeded"

struct PJS_Runtime_OpcodeCounting {
	U32	count;
	U32 limit;
};

typedef struct PJS_Runtime_OpcodeCounting PJS_Runtime_OpcodeCounting;

static JSTrapStatus opcount_interrupt_handler(JSContext *cx, JSScript *script, jsbytecode *pc, jsval *rval, void *closure) {
	PJS_Runtime *rt = (PJS_Runtime *) closure;
	PJS_Runtime_OpcodeCounting *opcount = (PJS_Runtime_OpcodeCounting *) rt->ext;
	
	opcount->count++;
	
	if (opcount->limit > 0 && opcount->count > opcount->limit) {
		sv_setsv(ERRSV, newRV_inc(newSViv(opcount->limit)));
		sv_bless(ERRSV, gv_stashpvn(PJS_ERROR_OPCODELILMIT_EXCEEDED, strlen(PJS_ERROR_OPCODELILMIT_EXCEEDED), TRUE));
		return JSTRAP_ERROR;
	}
	
	return JSTRAP_CONTINUE;
}

MODULE = JavaScript::Runtime::OpcodeCounting		PACKAGE = JavaScript::Runtime::OpcodeCounting

void
jsr_initialize(rt)
	PJS_Runtime *rt
	PREINIT:
		PJS_Runtime_OpcodeCounting *opcount;
	CODE:
		Newz(1, opcount, 1, PJS_Runtime_OpcodeCounting);
		if (opcount == NULL) {
			croak("Failed to allocate memory for PJS_Runtime_OpcodeCounting");
		}
		
		opcount->count = 0;
		opcount->limit = 0;
		
		rt->ext = (void *) opcount;
		
		JS_SetInterrupt(rt->rt, opcount_interrupt_handler, rt);		

void
jsr_destroy(rt)
	PJS_Runtime *rt;
	PREINIT:
		JSTrapHandler	trap_handler;
		void			*tmp;
	CODE:
		JS_ClearInterrupt(rt->rt, &trap_handler, &tmp);
		
		Safefree(rt->ext);
		rt->ext = NULL;
		
I32
jsr_get_opcount(rt)
	PJS_Runtime *rt;
	PREINIT:
		PJS_Runtime_OpcodeCounting *opcount;
	CODE:
		opcount = (PJS_Runtime_OpcodeCounting *) rt->ext;
		RETVAL = opcount->count;
	OUTPUT:
		RETVAL
		
void
jsr_set_opcount(rt,count)
	PJS_Runtime *rt;
	I32			count;
	PREINIT:
		PJS_Runtime_OpcodeCounting *opcount;
	CODE:
		opcount = (PJS_Runtime_OpcodeCounting *) rt->ext;
		opcount->count = count;
		
I32
jsr_get_opcount_limit(rt)
	PJS_Runtime *rt;
	PREINIT:
		PJS_Runtime_OpcodeCounting *opcount;
	CODE:
		opcount = (PJS_Runtime_OpcodeCounting *) rt->ext;
		RETVAL = opcount->limit;
	OUTPUT:
		RETVAL
		
void
jsr_set_opcount_limit(rt,limit)
	PJS_Runtime *rt;
	I32			limit;
	PREINIT:
		PJS_Runtime_OpcodeCounting *opcount;
	CODE:
		opcount = (PJS_Runtime_OpcodeCounting *) rt->ext;
		opcount->limit = limit;
