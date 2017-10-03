unit Util.UMetaDados;

interface

uses
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf,
  FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async,
  FireDAC.Phys, FireDAC.FMXUI.Wait, Data.DB, FireDAC.Comp.Client,
  Winapi.Windows, Firedac.Phys.SQLite;

type
  TBanco = class
  private
    procedure CriaTabela(Conexao: TFDConnection; pSQL: string);
  protected
    function GetSQLTSIGRUPO: string; virtual; abstract;
  public
    procedure CriaTabelas(Conexao: TFDConnection);
    procedure InserirDadosParaTeste(Conexao: TFDConnection);
  end;

  TBancoSQLite = class(TBanco)
    function GetSQLTSIGRUPO: string; override;
  end;

  TBancoOracle = class(TBanco)
    function GetSQLTSIGRUPO: string; override;
  end;

implementation

uses
  System.SysUtils;

{ TBanco }

procedure TBanco.CriaTabela(Conexao: TFDConnection; pSQL: string);
begin
  with TFDQuery.Create(nil) do
  try
    try
      Connection := Conexao;
      SQL.Add(pSQL);
      ExecSQL;
    except
    end;
  finally
    Free;
  end;
end;

procedure TBanco.CriaTabelas(Conexao: TFDConnection);
begin
  CriaTabela(Conexao, GetSQLTSIGRUPO);
end;

procedure TBanco.InserirDadosParaTeste(Conexao: TFDConnection);
begin
  with TFDQuery.Create(nil) do
  try
    try
      Connection := Conexao;
      SQL.Add('INSERT INTO TSIGRUPO VALUES(1, ''Gerente'', ''S'', ''gerentes@A2.com.br'');');
      SQL.Add('INSERT INTO TSIGRUPO VALUES(2, ''Vendedor'', ''S'', ''vendedor@A2.com.br'');');
      ExecSQL;
    except
    end;
  finally
    Free;
  end;
end;

{ TBancoSQLite }

function TBancoSQLite.GetSQLTSIGRUPO: string;
var
  Str: TStringBuilder;
begin
  Str := TStringBuilder.Create;
  try
    Str.Append('CREATE TABLE TSIGRUPO');
    Str.Append('(GRU_ID INT NOT NULL,');
    Str.Append(' GRU_NOME VARCHAR(50) NOT NULL,');
    Str.Append(' GRU_ATIVO CHAR(1),');
    Str.Append(' GRU_EMAIL VARCHAR(100),');
    Str.Append(' CONSTRAINT PK_GRUPO_ID PRIMARY KEY (GRU_ID)');
    Str.Append(')');
    Result := Str.ToString;
  finally
    Str.Free;
  end;
end;

{ TBancoOracle }

function TBancoOracle.GetSQLTSIGRUPO: string;
begin
  Result := '';
end;

end.
