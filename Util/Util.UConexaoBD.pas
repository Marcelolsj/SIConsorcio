unit Util.UConexaoBD;

interface

uses
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf,
  FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async,
  FireDAC.Phys, FireDAC.FMXUI.Wait, Data.DB, FireDAC.Comp.Client,
  Winapi.Windows, Firedac.Phys.SQLite, Util.UMetaDados;

type
  TConexaoBD = class
  private
    FConexao: TFDConnection;
    FSQLiteDriver: TFDPhysSQLiteDriverLink;
    FStrConexao: string;
    FSenha: string;
    FCaminhoBD: string;
    FPorta: Cardinal;
    FUsuario: string;
    FBanco: TBanco;

    procedure SetStrConexao;
    procedure SetCaminhoBD(const Value: string);
    procedure SetPorta(const Value: Cardinal);
    procedure SetSenha(const Value: string);
    procedure SetUsuario(const Value: string);
    procedure SetBanco(const Value: TBanco);

    function StrConexaoCompleta: Boolean;
  public
    function Conectar: Boolean;
    function GetID(NomeCampo: string): Integer;

    property Conexao: TFDConnection read FConexao;
    property StrConexao: string read FStrConexao;
    property CaminhoBD: string read FCaminhoBD write SetCaminhoBD;
    property Usuario: string read FUsuario write SetUsuario;
    property Senha: string read FSenha write SetSenha;
    property Porta: Cardinal read FPorta write SetPorta;
    property Banco: TBanco read FBanco write SetBanco;

    constructor Create;
    destructor Destroy; override;
  end;

implementation

uses
  System.SysUtils;

{ TConexaoBD }

function TConexaoBD.Conectar: Boolean;
var
  CriarTabelas: Boolean;
  HandleFile: Integer;
begin
  CriarTabelas := False;
  try
    FConexao.Close;
    FConexao.Params.Clear;

    if Banco = nil then
      raise Exception.Create('O tipo do banco de dados não foi definido.');

    if Banco is TBancoSQLite then
    begin
      if CaminhoBD = '' then
        raise Exception.Create('Nem todas as informações de conexão foram informadas.');

      if not (FileExists(CaminhoBD)) then
      begin
        HandleFile := FileCreate(CaminhoBD);
        FileClose(handleFile);
        CriarTabelas := True;
      end;

      FConexao.Params.Values['Database']     := CaminhoBD;
      FConexao.Params.Values['DriverID']     := 'SQLite';
      FConexao.Params.Values['CharacterSet'] := 'utf8';
    end
    else if Banco is TBancoOracle then
    begin
      if not StrConexaoCompleta then
        raise Exception.Create('Nem todas as informações de conexão foram informadas.');
    end;

    FConexao.Connected := True;

    if CriarTabelas then
    begin
      Banco.CriaTabelas(FConexao);
      Banco.InserirDadosParaTeste(FConexao);
    end;

    Result := True;
  except
    Result := False;
  end;
end;

constructor TConexaoBD.Create;
begin
  inherited;
  FConexao      := TFDConnection.Create(nil);
  FSQLiteDriver := TFDPhysSQLiteDriverLink.Create(FConexao);
end;

destructor TConexaoBD.Destroy;
begin
  FConexao.Close;
  FreeAndNil(FConexao);
  FreeAndNil(FSQLiteDriver);
  inherited;
end;

function TConexaoBD.GetID(NomeCampo: string): Integer;
begin
  { TODO -oMarcelo -cConexão : Criar função para retornar o próximo ID baseado num gerenator }
  Result := 1;
end;

procedure TConexaoBD.SetBanco(const Value: TBanco);
begin
  FBanco := Value;

  if FBanco is TBancoOracle then
    SetStrConexao;
end;

procedure TConexaoBD.SetCaminhoBD(const Value: string);
begin
  FCaminhoBD := Value;
end;

procedure TConexaoBD.SetPorta(const Value: Cardinal);
begin
  FPorta := Value;
end;

procedure TConexaoBD.SetSenha(const Value: string);
begin
  FSenha := Value;
end;

procedure TConexaoBD.SetStrConexao;
begin
  { TODO -oMarcelo -cConexão : Criar string de conexão com oracle }
end;

procedure TConexaoBD.SetUsuario(const Value: string);
begin
  FUsuario := Value;
end;

function TConexaoBD.StrConexaoCompleta: Boolean;
begin
  { TODO -oMarcelo -cConexão : Verificar se todos os dados de conexão estão preenchidos }
  Result := True;
end;

end.
