unit VO.UTSIGrupo;

interface

uses Classes, VO, Util.Atributos;

type
  [TEntity]
  [TTable('TSIGRUPO')]
  TGrupo = class(TVO)
  private
    FEmail: String;
    FAtivo: String;
    FId: Integer;
    FNome: String;
  public
    [TId('GRU_ID')]
    property Id: Integer read FId write FId;
    [TColumn('GRU_NOME')]
    property Nome: String read FNome write FNome;
    [TColumn('GRU_ATIVO')]
    property Ativo: String read FAtivo write FAtivo;
    [TColumn('GRU_EMAIL')]
    property Email: String read FEmail write FEmail;
  end;

implementation

initialization
  Classes.RegisterClass(TGrupo);

finalization
  Classes.UnRegisterClass(TGrupo);

end.
