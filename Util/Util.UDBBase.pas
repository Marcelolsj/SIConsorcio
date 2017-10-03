unit Util.UDBBase;

interface

uses Util.Atributos, Rtti, SysUtils, TypInfo, VO, Classes, Vcl.Forms, DB, DBClient,
    Generics.Collections, MaTh, Variants, System.JSON,
    FireDAC.Comp.Client, FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf,
    FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys,
    FireDAC.VCLUI.Wait, FireDAC.Stan.ExprFuncs, FireDAC.Phys.SQLite, FireDAC.Phys.IB, FireDAC.Phys.Oracle,
    FireDAC.Comp.UI, FireDAC.Stan.Param, FireDAC.DatS, FireDAC.DApt.Intf, FireDAC.DApt,
    FireDAC.Comp.DataSet, FireDAC.Comp.ScriptCommands, FireDAC.Stan.Util, FireDAC.Comp.Script;//, ULogArquivo;

type
  TDB = class
  private
    //class var FLogApp: TLogErro;
    class procedure LogApp(pValue: String);
  public
    class function getInsert(pConexao: TFDConnection; pObject: TObject; pQuatodStr: Boolean = True): String;
    class function Inserir(pConexao: TFDConnection; pObjeto: TObject): Integer; overload;
    class function Inserir(pConexao: TFDConnection; pListaObjeto: TObjectList<TVO>): Integer; overload;

    class function getAlterar(pConexao: TFDConnection; pObject: TObject): String;
    class function Alterar(pConexao: TFDConnection; pObjeto: TObject): Integer; overload;
    class function Alterar(pConexao: TFDConnection; pListaObjeto: TObjectList<TVO>): Integer; overload;

    class function getExcluir(pObject: TObject): String;
    class function Excluir(pConexao: TFDConnection; pObjeto: TObject): Integer; overload;
    class function Excluir(pConexao: TFDConnection; pListaObjeto: TObjectList<TVO>): Integer; overload;

    class function Consultar(pConexao: TFDConnection; pObjeto: TObject; pFiltro: String): TFDQuery; overload;
    class function Consultar(pConexao: TFDConnection; pObjeto: TVO; pFiltro: String): TVO; overload;
    class function Consultar<T: class>(pConexao: TFDConnection; pFiltro: String): TObjectList<T>; overload;
    class function Consultar(pConexao: TFDConnection; pConsulta: String): TFDQuery; overload;

    class function ComandoSQL(pConexao: TFDConnection; pConsulta: String): Integer;
    class function getID_Retaguarda(pConexao: TFDConnection; pCampo: String): Integer;
    class function getID(pConexao: TFDConnection; pCampo: String): Integer;
    class function getEntityName(pObject: TObject): String;
    class function getEntityIdName(pObject: TObject): String;

  end;

  TGenericVO<T: class> = class
  private
    class function CreateObject: T;
  public
    class function QueryToVO(pDataSet: TFDQuery): T;
  end;

implementation

//uses
//  Util.Constantes;

{ TDB }

{$Region 'Auxiliar'}
class procedure TDB.LogApp(pValue: String);
//var
//  vArquivo: String;
begin
//
//  vArquivo := (copy(ExtractFilePath(Application.ExeName), 1, pos('Aplicações', ExtractFilePath(Application.ExeName)) - 1)+ 'Log');
//  If not DirectoryExists(vArquivo) then
//    CreateDir(vArquivo);
//
//  vArquivo := vArquivo + '\'+FormatDateTime('yyyymmdd',Now)+'.log';
//  if not Assigned(FLogApp) then
//  begin
//    FLogApp := TLogErro.Create(vArquivo, True);
//    FLogApp.Grava:= True;
//  end;
//  FLogApp.PathArquivo := vArquivo;
//
//  FLogApp.EscreveArquivo(pValue);

end;

{$EndRegion}

{$Region 'Inserção de Dados'}
class function TDB.getID_Retaguarda(pConexao: TFDConnection; pCampo: String): Integer;
var
  vQuery: TFDQuery;
begin

  Result := 0;

  vQuery := TFDQuery.Create(nil);
  try
    with vQuery do
    begin
      Connection := pConexao;
      vQuery.Close;
      SQL.Text := 'select CAST(ID_' + pCampo + '.NEXTVAL AS NUMERIC(10)) COD from DUAL';
      try
        vQuery.Open;
        if not vQuery.IsEmpty then
          Result := vQuery.FieldByName('COD').AsInteger;
      except
        Result := 0;
      end;
    end;
  finally
    FreeAndNil(vQuery);
  end;

end;

class function TDB.getID(pConexao: TFDConnection; pCampo: String): Integer;
var
  vQuery: TFDQuery;
begin

  Result := 0;

  vQuery := TFDQuery.Create(nil);
  try
    with vQuery do
    begin
      Connection := pConexao;
      vQuery.Close;
      if (AnsiUpperCase(pConexao.DriverName) = 'ORA') then
        SQL.Text := 'select CAST(ID_' + pCampo + '.NEXTVAL AS NUMERIC(10)) COD from DUAL'
      else
        if (AnsiUpperCase(pConexao.DriverName) = 'IB') or (AnsiUpperCase(pConexao.DriverName) = 'FB') then
          SQL.Text := 'select GEN_ID (ID_' + pCampo + ', 1) COD FROM RDB$DATABASE';
      try
        vQuery.Open;
        if not vQuery.IsEmpty then
          Result := vQuery.FieldByName('COD').AsInteger;
      except
        on E: Exception do
        begin
          Result := 0;
          if (AnsiUpperCase(pConexao.DriverName) = 'IB') or (AnsiUpperCase(pConexao.DriverName) = 'FB') then
          begin
            pConexao.ExecSQL('CREATE GENERATOR ID_' + pCampo);
            Result := getID(pConexao, pCampo);
          end;
        end;

      end;
    end;
  finally
    FreeAndNil(vQuery);
  end;

end;

class function TDB.getInsert(pConexao: TFDConnection; pObject: TObject; pQuatodStr: Boolean): String;
var
  vContexto : TRttiContext;
  vTipo: TRttiType;
  vPropriedade: TRttiProperty;
  vAtributo: TCustomAttribute;
  vSQL : String;
  vSQL_Campos: String;
  vSQL_Valor: String;
  vVariant: Variant;

  function getQuotedStr(vValor: String): String;
  begin
    //if pQuatodStr then
      Result := '''' + vValor + '''';
    //else
    //  Result := vValor;
  end;
begin

  Result := '';
  try
    FormatSettings.DecimalSeparator := '.';
    vContexto := TRttiContext.Create;
    vTipo     := vContexto.GetType(pObject.ClassType);

    for vAtributo in vTipo.GetAttributes do
    begin
      if vAtributo is TTable then
      begin
        vSQL := 'INSERT INTO ' + (vAtributo as TTable).Name;
        break;
      end;
    end;

    for vPropriedade in vTipo.GetProperties do
    begin
      for vAtributo in vPropriedade.GetAttributes do
      begin
        if vAtributo is TColumn then
        begin
          if (vPropriedade.PropertyType.TypeKind = tkFloat) then
          begin
            vSQL_Campos := vSQL_Campos + (vAtributo as TColumn).Name + ',';
            if (AnsiUpperCase(vPropriedade.PropertyType.Name) = 'TDATETIME') then
            begin
              if vPropriedade.GetValue(pObject).AsExtended > 0 then
              begin
                if AnsiUpperCase(pConexao.DriverName) = 'ORA' then
                  vSQL_Valor := vSQL_Valor + getQuotedStr(FormatDateTime('DD/MM/YYYY HH:mm:ss',vPropriedade.GetValue(pObject).AsExtended)) + ','
                else
                  vSQL_Valor := vSQL_Valor + getQuotedStr(FormatDateTime('YYYY/MM/DD HH:mm:ss',vPropriedade.GetValue(pObject).AsExtended)) + ',';

              end else
                vSQL_Valor := vSQL_Valor + 'Null,';
            end else                      //QuotedStr
              vSQL_Valor := vSQL_Valor + getQuotedStr(FormatFloat('0.000',vPropriedade.GetValue(pObject).AsExtended)) + ',';
          end else
            if (vPropriedade.PropertyType.TypeKind in [tkInteger, tkInt64]) then
            begin
              vSQL_Campos := vSQL_Campos + (vAtributo as TColumn).Name + ',';

              if ((vAtributo as TColumn).ZeroToNull) and (vPropriedade.GetValue(pObject).ToString = '0') then
                vSQL_Valor  := vSQL_Valor + 'Null,'
              else                          //QuotedStr
                vSQL_Valor  := vSQL_Valor + getQuotedStr(vPropriedade.GetValue(pObject).ToString) + ',';

            end else
              if (vPropriedade.PropertyType.TypeKind = tkVariant) then
              begin
                vSQL_Campos := vSQL_Campos + (vAtributo as TColumn).Name + ',';

                vVariant := vPropriedade.GetValue(pObject).AsVariant;
                if (vVariant <> Unassigned) then  //getQuotedStr
                  vSQL_Valor  := vSQL_Valor + getQuotedStr(vVariant) + ','
                else
                  vSQL_Valor  := vSQL_Valor + 'Null,';

              end else
                begin                           //getQuotedStr
                  vSQL_Campos := vSQL_Campos + (vAtributo as TColumn).Name + ',';
                  vSQL_Valor  := vSQL_Valor + getQuotedStr(vPropriedade.GetValue(pObject).ToString) + ',';
                end;
        end else
          if vAtributo is TId then
          begin                             //getQuotedStr
            vSQL_Campos := vSQL_Campos + (vAtributo as TId).Name + ',';
            if (pConexao <> Nil) and (vPropriedade.GetValue(pObject).ToString = '0') then
              vSQL_Valor  := vSQL_Valor + getQuotedStr(IntToStr(getID(pConexao,(vAtributo as TId).Name))) + ','
            else
              vSQL_Valor  := vSQL_Valor + getQuotedStr(vPropriedade.GetValue(pObject).ToString) + ',';
          end;
      end;
    end;
    Delete(vSQL_Campos, Length(vSQL_Campos),1);
    Delete(vSQL_Valor, Length(vSQL_Valor),1);

    vSQL := vSQL + ' ('+ vSQL_Campos + ') VALUES ('+ vSQL_Valor +');';

    Result := vSQL;
  finally
    FormatSettings.DecimalSeparator := ',';
  end;

end;

class function TDB.Inserir(pConexao: TFDConnection; pObjeto: TObject): Integer;
var
  vQuery : TFDQuery;
  vSQL: String;
begin
  try
    Result := 0;
    FormatSettings.DecimalSeparator := '.';
    try
      vQuery := TFDQuery.Create(nil);
      vQuery.Connection := pConexao;
      vSQL:= getInsert(pConexao, pObjeto);
      Delete(vSQL, Length(vSQL),1);
      vQuery.sql.Text := vSQL;
      try
        vQuery.ExecSQL;
        Result := 1;
      Except
        on E: Exception do
        begin
          LogApp(vQuery.sql.Text);
          raise Exception.Create(E.Message);
        end;
      end;
    finally
      vQuery.Close;
      FreeAndNil(vQuery);
    end;

  finally
    FormatSettings.DecimalSeparator := ',';
  end;
end;

class function TDB.Inserir(pConexao: TFDConnection; pListaObjeto: TObjectList<TVO>): Integer;
var
  vTextSQL: String;
  vQry : TFDScript;
  vCount: Integer;
begin
  try
    Result     := 0;
    vTextSQL   := '';
    FormatSettings.DecimalSeparator := '.';

    for vCount := 0 to Pred(pListaObjeto.Count) do
    begin
      vTextSQL := vTextSQL + getInsert(pConexao, TObject(pListaObjeto[vCount]), AnsiUpperCase(pConexao.DriverName) <> 'ORA' ) + sLineBreak;
    end;

    if vTextSQL <> '' then
    begin
      vQry := TFDScript.Create(nil);
      try
        vQry.Connection := pConexao;
        vQry.SQLScripts.Clear;
        vQry.SQLScripts.Add;
        vQry.SQLScripts[0].SQL.Clear;
        vQry.SQLScripts[0].SQL.Text := vTextSQL;

        vQry.ValidateAll;
        if vQry.Status = ssFinishSuccess then
        begin
          vQry.ExecuteAll;
          if vQry.TotalErrors > 0 then
          begin
            LogApp(vTextSQL);
            raise Exception.Create('Error nos Dados');
          end;
          Result := 1;
        end else
          begin
            LogApp(vTextSQL);
            raise Exception.Create('Dados com Erro');
          end;

      finally
        FreeAndNil(vQry);
      end;
    end;
  finally
    FormatSettings.DecimalSeparator := ',';
  end;

end;
{$EndRegion}

{$Region 'Alteração de Dados'}
class function TDB.getAlterar(pConexao: TFDConnection; pObject: TObject): String;
var
  vContexto : TRttiContext;
  vTipo: TRttiType;
  vPropriedade: TRttiProperty;
  vAtributo: TCustomAttribute;
  vSQL : String;
  vSQL_Valor: String;
  vSQL_Filtro: String;
  vVariant: Variant;
begin

  Result := '';
  try
    FormatSettings.DecimalSeparator := '.';
    vContexto := TRttiContext.Create;
    vTipo     := vContexto.GetType(pObject.ClassType);

    for vAtributo in vTipo.GetAttributes do
    begin
      if vAtributo is TTable then
      begin
        vSQL := 'UPDATE ' + (vAtributo as TTable).Name + ' SET ';
        break;
      end;
    end;

    for vPropriedade in vTipo.GetProperties do
    begin
      for vAtributo in vPropriedade.GetAttributes do
      begin
        if vAtributo is TColumn then
        begin
          if (vPropriedade.PropertyType.TypeKind = tkFloat) then
          begin
            if (AnsiUpperCase(vPropriedade.PropertyType.Name) = 'TDATETIME') then
            begin
              if vPropriedade.GetValue(pObject).AsExtended > 0 then
              begin
                if AnsiUpperCase(pConexao.DriverName) = 'ORA' then
                  vSQL_Valor := vSQL_Valor + (vAtributo as TColumn).Name + ' = '  + QuotedStr(FormatDateTime('DD/MM/YYYY HH:mm:ss',vPropriedade.GetValue(pObject).AsExtended)) + ','
                else
                  vSQL_Valor := vSQL_Valor + (vAtributo as TColumn).Name + ' = '  + QuotedStr(FormatDateTime('YYYY/MM/DD HH:mm:ss',vPropriedade.GetValue(pObject).AsExtended)) + ',';
              end else
                vSQL_Valor := vSQL_Valor + (vAtributo as TColumn).Name + ' = '  + 'Null,';
            end else
              vSQL_Valor := vSQL_Valor + (vAtributo as TColumn).Name + ' = '  + QuotedStr(FormatFloat('0.000',vPropriedade.GetValue(pObject).AsExtended)) + ',';
          end else
            if (vPropriedade.PropertyType.TypeKind in [tkInteger, tkInt64]) then
            begin

              if ((vAtributo as TColumn).ZeroToNull) and (vPropriedade.GetValue(pObject).ToString = '0') then
                vSQL_Valor  := vSQL_Valor + (vAtributo as TColumn).Name + ' = '  + 'Null,'
              else
                vSQL_Valor  := vSQL_Valor + (vAtributo as TColumn).Name + ' = '  + QuotedStr(vPropriedade.GetValue(pObject).ToString) + ',';

            end else
              if (vPropriedade.PropertyType.TypeKind = tkVariant) then
              begin

                vVariant := vPropriedade.GetValue(pObject).AsVariant;
                if (vVariant <> Unassigned) then
                  vSQL_Valor  := vSQL_Valor + (vAtributo as TColumn).Name + ' = '  + QuotedStr(vVariant) + ','
                else
                  vSQL_Valor  := vSQL_Valor + (vAtributo as TColumn).Name + ' = '  + 'Null,';

              end else
                begin
                  vSQL_Valor  := vSQL_Valor + (vAtributo as TColumn).Name + ' = '  + QuotedStr(vPropriedade.GetValue(pObject).ToString) + ',';
                end;
        end else
          if vAtributo is TId then
          begin
            vSQL_Filtro  := ' WHERE ' + (vAtributo as TId).Name + ' = '  + QuotedStr(vPropriedade.GetValue(pObject).ToString);
          end;
      end;
    end;
    Delete(vSQL_Valor, Length(vSQL_Valor),1);

    vSQL := vSQL + vSQL_Valor + vSQL_Filtro + ';';

    Result := vSQL;
  finally
    FormatSettings.DecimalSeparator := ',';
  end;

end;

class function TDB.Alterar(pConexao: TFDConnection; pObjeto: TObject): Integer;
var
  vTextSQL: String;
  vQuery : TFDQuery;
begin
  Result := 0;
  vTextSQL:= getAlterar(pConexao, pObjeto);
  if (vTextSQL <> '') then
  begin
    try
      vQuery := TFDQuery.Create(Nil);
      vQuery.Connection := pConexao;
      vQuery.sql.Text := vTextSQL;
      vQuery.ExecSQL();

      Result := 1;
    finally
      vQuery.Close;
      FreeAndNil(vQuery);
    end;
  end;
end;

class function TDB.Alterar(pConexao: TFDConnection; pListaObjeto: TObjectList<TVO>): Integer;
var
  vTextSQL: String;
  vCount: Integer;
  vQry: TFDScript;
begin
  try
    Result := 0;
    vTextSQL := '';
    FormatSettings.DecimalSeparator := '.';
    for vCount := 0 to Pred(pListaObjeto.Count) do
    begin
      vTextSQL := vTextSQL + getAlterar(pConexao, TObject(pListaObjeto[vCount])) + sLineBreak;
    end;

    if (vTextSQL <> '') then
    begin
      vQry := TFDScript.Create(nil);
      try
        vQry.Connection := pConexao;
        vQry.SQLScripts.Clear;
        vQry.SQLScripts.Add;
        vQry.SQLScripts[0].SQL.Clear;
        vQry.SQLScripts[0].SQL.Text := vTextSQL;

        vQry.ValidateAll;
        if vQry.Status = ssFinishSuccess then
        begin
          vQry.ExecuteAll;
          if vQry.TotalErrors > 0 then
          begin
            raise Exception.Create('Error nos Dados');
          end;
          Result := 1;
        end else
          raise Exception.Create('Dados com Erro');

      finally
        vQry.Free;
      end;
    end;

  finally
    FormatSettings.DecimalSeparator := ',';
  end;
end;
{$EndRegion}

{$Region 'Exclusão de Dados'}

class function TDB.getEntityIdName(pObject: TObject): String;
var
  vContexto: TRttiContext;
  vTipo: TRttiType;
  vPropriedade: TRttiProperty;
  vAtributo: TCustomAttribute;
begin

  Result      := '';
  vContexto := TRttiContext.Create;
  vTipo := vContexto.GetType(pObject.ClassType);

  for vPropriedade in vTipo.GetProperties do
  begin
    for vAtributo in vPropriedade.GetAttributes do
    begin
      if vAtributo is TId then
      begin
        Result := (vAtributo as TId).Name;
        Exit;
      end;
    end;
  end;

end;

class function TDB.getEntityName(pObject: TObject): String;
var
  vContexto: TRttiContext;
  vTipo: TRttiType;
  vAtributo: TCustomAttribute;
begin

  Result      := '';
  vContexto := TRttiContext.Create;
  vTipo := vContexto.GetType(pObject.ClassType);

  for vAtributo in vTipo.GetAttributes do
  begin
    if vAtributo is TTable then
    begin
      Result := (vAtributo as TTable).Name;
      Exit;
    end;
  end;

end;

class function TDB.getExcluir(pObject: TObject): String;
var
  vContexto: TRttiContext;
  vTipo: TRttiType;
  vPropriedade: TRttiProperty;
  vAtributo: TCustomAttribute;
  vSQL: String;
  vSQL_Filtro: String;
begin
  vSQL        := '';
  vSQL_Filtro := '';
  Result      := '';
  try
    vContexto := TRttiContext.Create;
    vTipo := vContexto.GetType(pObject.ClassType);

    for vAtributo in vTipo.GetAttributes do
    begin
      if vAtributo is TTable then
        vSQL := 'DELETE FROM ' + (vAtributo as TTable).Name;
    end;

    for vPropriedade in vTipo.GetProperties do
    begin
      for vAtributo in vPropriedade.GetAttributes do
      begin
        if vAtributo is TId then
        begin
          vSQL_Filtro := ' WHERE ' + (vAtributo as TId).Name + ' = ' + QuotedStr(vPropriedade.GetValue(pObject).ToString);
        end;
      end;
    end;

    if (vSQL_Filtro = '') then
      Exit;

    Result := vSQL + vSQL_Filtro;

  finally
    vContexto.Free;
  end;

end;

class function TDB.Excluir(pConexao: TFDConnection; pObjeto: TObject): Integer;
var
  vSQL: String;
  vQuery : TFDQuery;
begin
  vSQL   := '';
  Result := 0;
  vQuery := TFDQuery.Create(Nil);
  try

    vSQL := getExcluir(pObjeto);
    if (vSQL = '') then
      Exit;

    vQuery.Connection := pConexao;
    vQuery.sql.Text := vSQL;
    vQuery.ExecSQL();

    Result := 1;
  finally
    FreeAndNil(vQuery);
  end;
end;

class function TDB.Excluir(pConexao: TFDConnection; pListaObjeto: TObjectList<TVO>): Integer;
var
  vTextSQL: String;
  vCount: Integer;
  vQry: TFDScript;
begin
  try
    Result := 0;
    vTextSQL := '';
    FormatSettings.DecimalSeparator := '.';
    for vCount := 0 to Pred(pListaObjeto.Count) do
    begin
      vTextSQL := vTextSQL + getExcluir(TObject(pListaObjeto[vCount])) + sLineBreak;
    end;

    if (vTextSQL <> '') then
    begin
      vQry := TFDScript.Create(nil);
      try
        vQry.Connection := pConexao;
        vQry.SQLScripts.Clear;
        vQry.SQLScripts.Add;
        vQry.SQLScripts[0].SQL.Clear;
        vQry.SQLScripts[0].SQL.Text := vTextSQL;

        vQry.ValidateAll;
        if vQry.Status = ssFinishSuccess then
        begin
          vQry.ExecuteAll;
          if vQry.TotalErrors > 0 then
          begin
            raise Exception.Create('Error nos Dados');
          end;
          Result := 1;
        end else
          raise Exception.Create('Dados com Erro');

      finally
        vQry.Free;
      end;
    end;

  finally
    FormatSettings.DecimalSeparator := ',';
  end;
end;

{$EndRegion}

{$Region 'Consultas de Dados'}

class function TDB.Consultar<T>(pConexao: TFDConnection; pFiltro: String): TObjectList<T>;
var
  vQry : TFDQuery;
  vVO: TObject;
  vItem: T;
begin

  Result := TObjectList<T>.Create;
  vVO := TClass(T).Create;

  vQry := Consultar(pConexao, vVO, pFiltro);
  vQry.First;
  while not vQry.Eof do
  begin
    vItem := TGenericVO<T>.QueryToVO(vQry);
    Result.Add(vItem);
    vQry.Next;
  end;

end;

class function TDB.Consultar(pConexao: TFDConnection; pObjeto: TObject; pFiltro: String): TFDQuery;
var
  vContexto: TRttiContext;
  vTipo: TRttiType;
  vAtributo: TCustomAttribute;
  vConsultaSQL: String;
  vFiltroSQL: String;
begin
  Result := nil;
  try
    try
      vContexto := TRttiContext.Create;
      vTipo := vContexto.GetType(pObjeto.ClassType);

      for vAtributo in vTipo.GetAttributes do
      begin
        if vAtributo is TTable then
        begin
          vConsultaSQL := 'SELECT * FROM ' + (vAtributo as TTable).Name;
        end;
      end;

      if pFiltro <> '' then
      begin
        vFiltroSQL := ' WHERE ' + pFiltro;
      end;

      vConsultaSQL := vConsultaSQL + vFiltroSQL;

      Result := TFDQuery.Create(Nil);
      Result.Close;
      Result.Connection := pConexao;
      Result.SQL.Text := vConsultaSQL;
      Result.Open;
    except
      raise ;
    end;
  finally
    vContexto.Free;
  end;
end;

class function TDB.Consultar(pConexao: TFDConnection; pConsulta: String): TFDQuery;
begin
  try
    Result := TFDQuery.Create(Nil);
    Result.Connection := pConexao;
    Result.SQL.Text := pConsulta;
    Result.Prepare;
    Result.ExecSQL;
  except
    raise ;
  end;

end;

class function TDB.Consultar(pConexao: TFDConnection; pObjeto: TVO; pFiltro: String): TVO;
var
  vQry : TFDQuery;
  vVO: TObject;
begin

  //Result := TObjectList<TVO>.Create;
  vVO := TClass(TVO).Create;

  vQry := Consultar(pConexao, vVO, pFiltro);
  vQry.First;
  //if not vQry.IsEmpty then
  Result := TGenericVO<TVO>.QueryToVO(vQry);

end;

{$EndRegion}

{$Region 'SQL Geral'}
class function TDB.ComandoSQL(pConexao: TFDConnection; pConsulta: String): Integer;
var
   vQuery : TFDQuery;
begin
  Result := 0;
  vQuery := TFDQuery.Create(nil);
  try
    try
      vQuery.Connection := pConexao;
      vQuery.sql.Text := pConsulta;
      vQuery.ExecSQL();
      Result := 1;
    except
      raise ;
    end;
  finally
    vQuery.Close;
    FreeAndNil(vQuery);
  end;
end;
{$EndRegion}

{$Region 'TGenericVO'}
{ TGenericVO<T> }

class function TGenericVO<T>.CreateObject: T;
var
  Contexto: TRttiContext;
  Tipo: TRttiType;
  Value: TValue;
  Obj: TObject;
begin
  Contexto := TRttiContext.Create;
  try
    Tipo := Contexto.GetType(TClass(T));
    Value := Tipo.GetMethod('Create').Invoke(Tipo.AsInstance.MetaclassType, []);
    Result := T(Value.AsObject);
  finally
    Contexto.Free;
  end;

end;

class function TGenericVO<T>.QueryToVO(pDataSet: TFDQuery): T;
var
  vContexto: TRttiContext;
  vTipo: TRttiType;
  vPropriedade: TRttiProperty;
  vPropriedades: TArray<TRttiProperty>;
  vAtributo: TCustomAttribute;
  vValue: TValue;
  vField, vFieldValue: Integer;
  vFieldName: string;
  vEncontrouFieldValue: Boolean;
  vObject: T;
begin

  vObject := CreateObject;
  vContexto := TRttiContext.Create;
  try
    vTipo := vContexto.GetType(TObject(vObject).ClassType);
    vPropriedades := vTipo.GetProperties;
    if not pDataSet.IsEmpty then
    begin

      for vField := 0 to pDataSet.FieldCount - 1 do
      begin
       with pDataSet  do
        begin
          vValue := TValue.Empty;
          vFieldName := pDataSet.Fields[vField].FieldName;
          case Fields[vField].DataType of
            ftString:
              vValue := Fields[vField].AsString;

            ftDate:
              begin
                if Fields[vField].AsDateTime > 0 then
                  vValue := Fields[vField].AsDateTime
                else
                  vValue := TValue.Empty;
              end;

            ftDateTime, ftTimeStamp:
              begin
                if Fields[vField].AsDateTime > 0 then
                  vValue := Fields[vField].AsDateTime
                else
                  vValue := TValue.Empty;
              end;

            ftTime:
              begin
                if Fields[vField].AsDateTime > 0 then
                  vValue := Fields[vField].AsDateTime
                else
                  vValue := TValue.Empty;
              end;

            ftInteger:
              begin
                if Fields[vField].IsNull then
                  vValue := TValue.Empty
                else
                  vValue := Fields[vField].AsInteger;
              end;

            ftBCD, ftFloat, ftFMTBcd, ftCurrency:
              begin
                if Fields[vField].IsNull then
                  vValue := TValue.Empty
                else
                  vValue := Fields[vField].AsFloat;
              end;

            ftBoolean:
              vValue := Fields[vField].AsBoolean;

            ftBlob, ftBytes, ftVariant, ftOraClob, ftOraBlob:
              vValue := TValue.FromVariant(Fields[vField].AsVariant);

          else
            vValue := TValue.Empty;
          end;
        end;

        vEncontrouFieldValue := False;
        for vFieldValue := 0 to Length(vPropriedades) - 1 do
        begin
          vPropriedade := vPropriedades[vFieldValue];
          for vAtributo in vPropriedade.GetAttributes do
          begin
            if vAtributo is TColumn then
            begin
              if (vAtributo as TColumn).Name = vFieldName then
              begin
                if not vValue.IsEmpty then
                begin
                  vPropriedade.SetValue(TObject(vObject), vValue);
                end;

                vEncontrouFieldValue := True;
                Break;
              end;
            end
            else if vAtributo is TId then
            begin
              if (vAtributo as TId).Name = vFieldName then
              begin
                if not vValue.IsEmpty then
                begin
                  vPropriedade.SetValue(TObject(vObject), vValue);
                end;

                vEncontrouFieldValue := True;
                Break;
              end;
            end;
          end;

          if vEncontrouFieldValue then
            Break;
        end;
      end;

    end;
  finally
    vContexto.Free;
  end;
  Result := vObject;
end;
{$EndRegion}
end.
