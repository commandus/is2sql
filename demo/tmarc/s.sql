SELECT rownum, RNO, RVAL 
FROM marc.mrec r
where rno in (
:WORDS
)