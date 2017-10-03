unit Util.UCRUDHelper;

interface

uses
  System.JSON, VO, FireDAC.Comp.Client, Util.UConversor, Util.UDBBase;

type
  TCRUDHelper = class
  public
    class function Consulta(ConexaoBD: TFDConnection; Classe: TClassVO; Filtro: String = ''): TJSONArray;
    class function Inserir1Registro(ConexaoBD: TFDConnection; Classe: TClassVO; JSONValue: TJSONValue): String;
    class function Atualizar1Registro(ConexaoBD: TFDConnection; Classe: TClassVO; JSONValue: TJSONValue): String;
    class function Deletar1Registro(ConexaoBD: TFDConnection; VO: TVO): String;
  end;

implementation

uses
  System.SysUtils;

{ TCRUDHelper }

class function TCRUDHelper.Consulta(ConexaoBD: TFDConnection; Classe: TClassVO;
  Filtro: String): TJSONArray;
var
  VO: TVO;
begin
  VO := Classe.Create;
  try
    Result := TConversor.DataSetToJSON(TDB.Consultar(ConexaoBD, TObject(VO), Filtro), False);
  finally
    VO.Free;
  end;
end;

class function TCRUDHelper.Deletar1Registro(ConexaoBD: TFDConnection;
  VO: TVO): String;
begin
  try
    TDB.Excluir(ConexaoBD, VO);
    Result := 'Registro excluído com sucesso.';
  except
    on E: Exception do
      raise Exception.Create('Não foi possível excluir o registro do banco de dados.' + sLineBreak +
                             'Erro original: ' + E.Message);
  end;
end;

class function TCRUDHelper.Inserir1Registro(ConexaoBD: TFDConnection;
  Classe: TClassVO; JSONValue: TJSONValue): String;
var
  VO: TVO;
begin
  try
    VO := Classe.Create;
    try
      VO.SetValuesFromJSON(JSONValue);
      TDB.Inserir(ConexaoBD, VO);
      Result := 'Registro salvo com sucesso.';
    finally
      VO.Free;
    end;
  except
    on E: Exception do
      raise Exception.Create('Não foi possível inserir o registro no banco de dados.' + sLineBreak +
                             'Erro original: ' + E.Message);
  end;
end;

class function TCRUDHelper.Atualizar1Registro(ConexaoBD: TFDConnection;
  Classe: TClassVO; JSONValue: TJSONValue): String;
var
  VO: TVO;
begin
  try
    VO := Classe.Create;
    try
      VO.SetValuesFromJSON(JSONValue);
      TDB.Alterar(ConexaoBD, VO);
      Result := 'Registro salvo com sucesso.';
    finally
      VO.Free;
    end;
  except
    on E: Exception do
      raise Exception.Create('Não foi possível inserir o registro no banco de dados.' + sLineBreak +
                             'Erro original: ' + E.Message);
  end;
end;

end.
