unit Util.Atributos;

interface

uses Classes, SysUtils, Variants, DB;

type

  TEntity = class(TCustomAttribute)
  end;

  TTable = class(TCustomAttribute)
  private
    FName: String;
  public
    constructor Create(pName: String);
    property Name: String read FName write FName;
  end;

  TId = class(TCustomAttribute)
  private
    FName: String;
  public
    constructor Create(pName: String);
    property Name: String read FName write FName;
  end;

  TColumn = class(TCustomAttribute)
  private
    FName: String;
    FZeroToNull: Boolean;
    FColumnKey: string;
  public
    constructor Create(pName: String); overload;
    constructor Create(pName: String; pZeroToNull: Boolean); overload;
    constructor Create(pName: String; pColumnKey: String); overload;
    property Name: String read FName write FName;
    property ZeroToNull: Boolean read FZeroToNull write FZeroToNull;
    property ColumnKey: string read FColumnKey write FColumnKey;

  end;

  TCallForm = class(TCustomAttribute)
  private
    FClassName: string;

  public
    constructor Create(ClassName: string);
    property ClassName: string read FClassName;
  end;


implementation

{$Region 'TTable'}
constructor TTable.Create(pName: String);
begin
  FName := pName;
end;
{$EndRegion 'TTable'}

{$Region 'TId'}
constructor TId.Create(pName: String);
begin
  FName := pName;
end;
{$EndRegion 'TId'}

{$Region 'TColumn'}
constructor TColumn.Create(pName: String);
begin
  FName := pName;
  FZeroToNull := False;
end;

constructor TColumn.Create(pName: String; pZeroToNull: Boolean);
begin
  FName := pName;
  FZeroToNull := pZeroToNull;
end;

constructor TColumn.Create(pName, pColumnKey: String);
begin
  FName := pName;
  FColumnKey := pColumnKey;
end;
{$EndRegion 'TColumn'}

{ TCallForm }

constructor TCallForm.Create(ClassName: string);
begin
  FClassName := ClassName;
end;

end.
