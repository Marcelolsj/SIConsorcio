unit Util.UFuncoesGerais;

interface

function iif(Condicao: Boolean; ValorVerdadeiro, ValorFalso: Variant): Variant;

implementation

function iif(Condicao: Boolean; ValorVerdadeiro, ValorFalso: Variant): Variant;
begin
  if Condicao then
    Result := ValorVerdadeiro
  else
    Result := ValorFalso;
end;

end.
