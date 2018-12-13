unit logmeter;
(*##*)
(*******************************************************************
*                                                                 *
*   L  O  G  M  E  T  E  R  IS2SQL logging routines                *
*                                                                 *
*   Copyright (c) 1999, Андрей Иванов                              *
*   вспомогательные функции                                       *
*   Part of is2sql                                                 *
*                                                                 *
*   for more information see readme.txt                            *
*                                                                 *
*   Conditional defines:                                           *
*                                                                 *
*   Last Revision: Jan 18 1999                                     *
*   Last fix     : Jan 18 1999                                    *
*   Lines        :                                                 *
*   History      :                                                *
*   Printed      : ---                                             *
*                                                                 *
********************************************************************)
(*##*)

interface

uses
  isutil1;

type
  THits = array [0..1] of TLogStruc;

procedure AddHit(AHit: TLogStruc; AHits: THits; AHitLen: Integer);

implementation

procedure AddHit(AHit: TLogStruc; AHits: THits; AHitLen: Integer);
begin
  // Move(AHits[1], AHits[0], Sizeof(TLogStruc) * (AHitLen - 1));
  AHits[AHitLen -1]:= AHit;
end;

end.
