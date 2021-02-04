#INCLUDE "PROTHEUS.CH"
#INCLUDE "FWMVCDEF.CH"

/*
______________________________________________________________________________
|_____________________________________________________________________________|
|Programa  - MFAT001    Autor  Fabricio Antunes      Data   22/11/2020   	  |
|_____________________________________________________________________________|
|Descricao|Funcao de remarcacao de preco versao 2.0                           |
|         |                                                                   |
|_________|___________________________________________________________________|
|Uso      | Geral                                                         | 
|_________|___________________________________________________________________|
|_____________________________________________________________________________|
*/


User Function MFAT001()

    Local aCampos    := {}
    Local cArqTrb
    Local cIndice1, cIndice2, cIndice3:= ""
    Local lMarcar      := .F.
    Local aSeek   := {}
	Local aPergs   := {}
	Local dDataDe  := FirstDate(Date())
	Local dDataAt  := LastDate(Date())
    Local cNota
    Local cSerie
    Local cFornece
    Local cLoja
    Local cQuery:=""
	Private cAliasT := "TRB"
	Private oBrowse := Nil	
    Private nVias   :=1
    Private cCadastro     := "Precificao Geral"
    Private aRotina         := Menudef() //Se for criar menus via MenuDef
    Private cAliasTRB:="TRB"
    
	// pergunta data ao abrir a tela
	aAdd(aPergs, {1, "Data De",  dDataDe,  "", ".T.", "", ".T.", 80,  .F.})
	aAdd(aPergs, {1, "Data Ate", dDataAt,  "", ".T.", "", ".T.", 80,  .T.})
    aAdd(aPergs, {1, "Nota Fiscal", Space(9),  "@!", ".T.", "SF1", ".T.", 9,  .F.})
	aAdd(aPergs, {1, "Serie", Space(3),  "@!", ".T.", "", ".T.", 3,  .F.})
	aAdd(aPergs, {1, "Fornecedor", Space(6),  "@!", ".T.", "SA1", ".T.", 6,  .F.})
	aAdd(aPergs, {1, "Loja", Space(4),  "@!", ".T.", "", ".T.", 4,  .F.})
	aAdd(aPergs, {1, "Numero Vias",1,"@E 999","mv_par07>=1","","",3,.T.}) 

	If ParamBox(aPergs, "Informe os parâmetros")
		cEmissDe  := dtos(MV_PAR01)
		cEmissAte := dtos(MV_PAR02)
        cNota     := MV_PAR03
        cSerie    := MV_PAR04
        cFornece  := MV_PAR05
        cLoja     := MV_PAR06
        nVias     := MV_PAR07
       
	EndIf

    cQuery +=  " SELECT '   ' AS TRB_MARK,LTRIM(RTRIM(B1_GRUPO)) AS B1_GRUPO, LTRIM(RTRIM(BM_DESC)) AS BM_DESC, LTRIM(RTRIM(B1_COD)) AS B1_COD, LTRIM(RTRIM(B1_DESC)) AS B1_DESC, LTRIM(RTRIM(B1_CODBAR)) AS B1_CODBAR, SD1.D1_EMISSAO, SD1.D1_VUNIT, DA1.DA1_PRCVEN, SB1.B1_MARKUP, SB1.B1_PICM "
	cQuery += " ,(SD1.D1_VUNIT/((SB1.B1_MARKUP+SB1.B1_PICM-100)/100))*-1 PRCSUG" // preço sugerido
	cQuery += " ,(SD1.D1_VUNIT/((SB1.B1_MARKUP+SB1.B1_PICM-100)/100))*-1-DA1.DA1_PRCVEN DIFVALOR"  //diferença em valor 12-10 = 2
	cQuery += " ,(((SD1.D1_VUNIT/((SB1.B1_MARKUP+SB1.B1_PICM-100)/100))*-1 )/DA1.DA1_PRCVEN*100)-100 DIFPERC  "	// diferença em percentual 12/10*100-100=20
	cQuery += " ,SD1.R_E_C_N_O_ D1_RECNO, DA1.R_E_C_N_O_ DA1_RECNO"
	cQuery +=  " FROM"
	cQuery +=  " SB1010 SB1 INNER JOIN SD1010 SD1 ON B1_COD = D1_COD
	cQuery +=  " INNER JOIN DA1010 DA1 ON B1_COD = DA1_CODPRO
	cQuery +=  " INNER JOIN SBM010 SBM ON B1_GRUPO = BM_GRUPO
	cQuery +=  " WHERE"
	cQuery +=  " SB1.D_E_L_E_T_ = ''"
	cQuery +=  " AND SD1.D_E_L_E_T_ = ''"
	cQuery +=  " AND DA1.D_E_L_E_T_ = ''"
	cQuery +=  " AND SB1.B1_FILIAL = '" + xFilial("SB1") + "'"
	cQuery +=  " AND SD1.D1_FILIAL = '" + xFilial("SD1") + "'"
	cQuery +=  " AND DA1.DA1_FILIAL = '" + xFilial("DA1") + "'"
    cQuery +=  " AND SBM.BM_FILIAL = '" + xFilial("SBM") + "'"
    cQuery +=  " AND DA1.DA1_CODTAB = '"+GetMV("MV_TABPAD")+"' "
	//cQuery +=  " AND D1_XFRMPRE <> 'S'
	cQuery +=  " AND SD1.D1_EMISSAO BETWEEN '"+cEmissDe +"' AND '" +cEmissAte + "'"	
    IF Alltrim(cNota) <> ''
        cQuery +=  " AND SD1.D1_DOC = '"+cNota+"'"
    EndIF

    IF Alltrim(cSerie) <> ''
        cQuery +=  " AND SD1.D1_SERIE = '"+cSerie+"'"
    EndIF

    IF Alltrim(cFornece) <> ''
        cQuery +=  " AND SD1.D1_FORNECE = '"+cFornece+"'"
    EndIF

    IF Alltrim(cLoja) <> ''
        cQuery +=  " AND SD1.D1_LOJA = '"+cLoja+"'"
    EndIF

	cQuery += " Order by B1_DESC "



    //Criar a tabela temporária
    AAdd(aCampos,{"TRB_MARK","C",3,0})
    AAdd(aCampos,{"B1_GRUPO"    ,TamSX3('B1_GRUPO')[3]      ,TamSX3('B1_GRUPO')[1]  ,TamSX3('B1_GRUPO')[2]})
    AAdd(aCampos,{"BM_DESC"      ,TamSX3('BM_DESC')[3]      ,TamSX3('BM_DESC')[1]   ,TamSX3('BM_DESC')[2]})
    AAdd(aCampos,{"B1_COD"       ,TamSX3('B1_COD')[3]       ,TamSX3('B1_COD')[1]    ,TamSX3('B1_COD')[2]})
    AAdd(aCampos,{"B1_DESC"      ,TamSX3('B1_DESC')[3]      ,TamSX3('B1_DESC')[1]   ,TamSX3('B1_DESC')[2]})
    AAdd(aCampos,{"B1_CODBAR"    ,TamSX3('B1_CODBAR')[3]    ,TamSX3('B1_CODBAR')[1] ,TamSX3('B1_CODBAR')[2]})
    AAdd(aCampos,{"D1_EMISSAO"   ,TamSX3('D1_EMISSAO')[3]   ,TamSX3('D1_EMISSAO')[1],TamSX3('D1_EMISSAO')[2]})
    AAdd(aCampos,{"D1_VUNIT"     ,TamSX3('D1_VUNIT')[3]     ,TamSX3('D1_VUNIT')[1]  ,TamSX3('D1_VUNIT')[2]})
    AAdd(aCampos,{"DA1_PRCVEN"   ,TamSX3('DA1_PRCVEN')[3]   ,TamSX3('DA1_PRCVEN')[1],TamSX3('DA1_PRCVEN')[2]})
    AAdd(aCampos,{"B1_MARKUP"    ,TamSX3('B1_MARKUP')[3]    ,TamSX3('B1_MARKUP')[1] ,TamSX3('B1_MARKUP')[2]})
    AAdd(aCampos,{"B1_PICM"      ,TamSX3('B1_PICM')[3]      ,TamSX3('B1_PICM')[1]   ,TamSX3('B1_PICM')[2]})
    AAdd(aCampos,{"PRCSUG"       ,TamSX3('DA1_PRCVEN')[3]   ,TamSX3('DA1_PRCVEN')[1],TamSX3('DA1_PRCVEN')[2]})
    AAdd(aCampos,{"DIFVALOR"     ,TamSX3('DA1_PRCVEN')[3]   ,TamSX3('DA1_PRCVEN')[1],TamSX3('DA1_PRCVEN')[2]})
    AAdd(aCampos,{"DIFPERC"     ,"N",12,2})        
    AAdd(aCampos,{"D1_RECNO"    ,"N",8,0})   
    AAdd(aCampos,{"DA1_RECNO"   ,"N",8,0})   

   
    //Se o alias estiver aberto, fechar para evitar erros com alias aberto
    If (Select("TRB") <> 0)
        dbSelectArea("TRB")
        TRB->(dbCloseArea ())
    Endif
    //A função CriaTrab() retorna o nome de um arquivo de trabalho que ainda não existe e dependendo dos parâmetros passados, pode criar um novo arquivo de trabalho.
    cArqTrb   := CriaTrab(aCampos,.T.)
    DbUseArea(.T., "DBFCDX", cArqTrb, cAliasTRB, .T., .F.)
    
    //Criar indices
    cIndice1 := Alltrim(CriaTrab(,.F.))
    cIndice2 := cIndice1
    cIndice3 := cIndice1
   
    
    cIndice1 := Left(cIndice1,5) + Right(cIndice1,2) + "A"
    cIndice2 := Left(cIndice2,5) + Right(cIndice2,2) + "B"
    cIndice3 := Left(cIndice3,5) + Right(cIndice3,2) + "C"
   
    
    //Se indice existir excluir
    If File(cIndice1+OrdBagExt())
        FErase(cIndice1+OrdBagExt())
    EndIf
    If File(cIndice2+OrdBagExt())
        FErase(cIndice2+OrdBagExt())
    EndIf
    If File(cIndice3+OrdBagExt())
        FErase(cIndice3+OrdBagExt())
    EndIf
    


    //A função IndRegua cria um índice temporário para o alias especificado, podendo ou não ter um filtro
    IndRegua("TRB", cIndice1, "B1_DESC"     ,,, "Descricao")
    IndRegua("TRB", cIndice2, "B1_CODBAR"   ,,, "Codigo de Barras")
    IndRegua("TRB", cIndice3, "B1_COD"      ,,, "Codigo")

    
    //Fecha todos os índices da área de trabalho corrente.
    dbClearIndex()
    //Acrescenta uma ou mais ordens de determinado índice de ordens ativas da área de trabalho.
    dbSetIndex(cIndice1+OrdBagExt())
    dbSetIndex(cIndice2+OrdBagExt())
    dbSetIndex(cIndice3+OrdBagExt())


    SqlToTrb(cQuery,aCampos,"TRB")
    
    //Funcao para autaliacao da regra de ICMS 
    AtuICM()


    TRB->(DbGoTop())
    
    If TRB->(!Eof())
        //Irei criar a pesquisa que será apresentada na tela
        aAdd(aSeek,{"Descricao"             ,{{"",TamSX3('B1_DESC')[3],TamSX3('B1_DESC')[1],TamSX3('B1_DESC')[2],"Descricao"    ,"@!"}} } )
        aAdd(aSeek,{"Codigo de Barras"      ,{{"",TamSX3('B1_CODBAR')[3],TamSX3('B1_CODBAR')[1],TamSX3('B1_CODBAR')[2],"Codigo de Barras"    ,"@!"}} } )
        aAdd(aSeek,{"Codigo"                ,{{"",TamSX3('B1_COD')[3],TamSX3('B1_COD')[1],TamSX3('B1_COD')[2],"Codigo"    ,"@!"}} } )
  
        oBrowse:= FWMarkBrowse():New()
        oBrowse:SetDescription(cCadastro) //Titulo da Janela
        oBrowse:SetAlias("TRB") //Indica o alias da tabela que será utilizada no Browse
        oBrowse:SetFieldMark("TRB_MARK") //Indica o campo que deverá ser atualizado com a marca no registro
        oBrowse:oBrowse:SetDBFFilter(.T.)
        oBrowse:oBrowse:SetUseFilter(.T.) //Habilita a utilização do filtro no Browse
        oBrowse:oBrowse:SetFixedBrowse(.T.)
        oBrowse:SetWalkThru(.F.) //Habilita a utilização da funcionalidade Walk-Thru no Browse
        oBrowse:SetAmbiente(.T.) //Habilita a utilização da funcionalidade Ambiente no Browse
        oBrowse:SetTemporary(.T.) //Indica que o Browse utiliza tabela temporária
        oBrowse:oBrowse:SetSeek(.T.,aSeek) //Habilita a utilização da pesquisa de registros no Browse
        oBrowse:oBrowse:SetFilterDefault("") //Indica o filtro padrão do Browse


        //Adiciona uma coluna no Browse em tempo de execução
        oBrowse:SetColumns(MCFG006TIT("B1_GRUPO"      ,"Grupo"           ,03,X3Picture("B1_GRUPO")      ,1,TamSX3('B1_GRUPO')[1]    ,TamSX3('B1_GRUPO')[2]))
        oBrowse:SetColumns(MCFG006TIT("BM_DESC"       ,"Desc Grupo"      ,04,X3Picture("BM_DESC")       ,1,TamSX3('BM_DESC')[1]     ,TamSX3('BM_DESC')[2]))
        oBrowse:SetColumns(MCFG006TIT("B1_COD"        ,"Codigo"          ,05,X3Picture("B1_COD")        ,1,TamSX3('B1_COD')[1]      ,TamSX3('B1_COD')[2]))
        oBrowse:SetColumns(MCFG006TIT("B1_DESC"       ,"Descricao"       ,06,X3Picture("B1_DESC")       ,1,TamSX3('B1_DESC')[1]     ,TamSX3('B1_DESC')[2]))
        oBrowse:SetColumns(MCFG006TIT("B1_CODBAR"     ,"Cod Barras"      ,07,X3Picture("B1_CODBAR")     ,1,TamSX3('B1_CODBAR')[1]   ,TamSX3('B1_CODBAR')[2]))
        oBrowse:SetColumns(MCFG006TIT("D1_EMISSAO"    ,"Emissao"         ,08,X3Picture("D1_EMISSAO")    ,1,TamSX3('D1_EMISSAO')[1]  ,TamSX3('D1_EMISSAO')[2]))
        oBrowse:SetColumns(MCFG006TIT("D1_VUNIT"      ,"Preco Compra"    ,09,X3Picture("D1_VUNIT")      ,1,TamSX3('D1_VUNIT')[1]    ,TamSX3('D1_VUNIT')[2]))
        oBrowse:SetColumns(MCFG006TIT("B1_MARKUP"     ,"Markup"          ,10,X3Picture("B1_MARKUP")     ,2,TamSX3('B1_MARKUP')[1]   ,TamSX3('B1_MARKUP')[2]))
        oBrowse:SetColumns(MCFG006TIT("B1_PICM"       ,"Aliq ICM"        ,11,X3Picture("B1_PICM")       ,2,TamSX3('B1_PICM')[1]     ,TamSX3('B1_PICM')[2]))
        oBrowse:SetColumns(MCFG006TIT("PRCSUG"        ,"Preco Sugerido"  ,12,X3Picture("D1_VUNIT")      ,2,TamSX3('DA1_PRCVEN')[1]  ,TamSX3('DA1_PRCVEN')[2]))
        oBrowse:SetColumns(MCFG006TIT("DA1_PRCVEN"    ,"Preco Atual"     ,13,X3Picture("DA1_PRCVEN")    ,2,TamSX3('DA1_PRCVEN')[1]  ,TamSX3('DA1_PRCVEN')[2]))
        oBrowse:SetColumns(MCFG006TIT("DIFVALOR"      ,"Dif Valor"       ,14,X3Picture("D1_VUNIT")      ,2,TamSX3('DA1_PRCVEN')[1]  ,TamSX3('DA1_PRCVEN')[2]))
        oBrowse:SetColumns(MCFG006TIT("DIFPERC"       ,"Dif Percen"      ,15,X3Picture("B1_PICM")       ,0,12  ,2))

        SetFunName("MFAT001")    
        oBrowse:AddButton("Atualizar Preços"    , { || MsgRun('Atualizando Precos','Atualiza',{|lEnd| GravaDA1(@lEnd) }) },,,, .F., 2 )
        oBrowse:AddButton("Imprimir Etiquetas"  , { || MsgRun('Imprimindo Etiquetas','Relatório',{|lEnd| ImpEtiq(@lEnd) }) },,,, .F., 2 )
        //oBrowse:AddButton("Imprimir Etiquetas"  , { ||  MsAguarde({|lEnd| ImpEtiq(@lEnd) },,,, .F., 2 )
        
        //Indica o Code-Block executado no clique do header da coluna de marca/desmarca
        oBrowse:bAllMark := { || MCFG6Invert(oBrowse:Mark(),lMarcar := !lMarcar ), oBrowse:Refresh(.T.)  }
        //Método de ativação da classe
        oBrowse:Activate()
        
        oBrowse:oBrowse:Setfocus() //Seta o foco na grade
    Else
        MsgInfo("Nao ha dados para serem apresentados para os filtros preenchidos, verique se os produtos já estao na tabela de preco")
        Return
    EndIf
    
    //Limpar o arquivo temporário
    If !Empty(cArqTrb)
        Ferase(cArqTrb+GetDBExtension())
        Ferase(cArqTrb+OrdBagExt())
        cArqTrb := ""
        TRB->(DbCloseArea())
    Endif
Return(.T.)


/*
______________________________________________________________________________
|_____________________________________________________________________________|
|Programa  - MCFG6Invert    Autor  Fabricio Antunes      Data   22/11/2020   	  |
|_____________________________________________________________________________|
|Descricao|Controle de Marcacao                                               |
|         |                                                                   |
|_________|___________________________________________________________________|
|Uso      | Geral                                                         | 
|_________|___________________________________________________________________|
|_____________________________________________________________________________|
*/
Static Function MCFG6Invert(cMarca,lMarcar)
    Local cAliasSD1 := 'TRB'
    Local aAreaSD1  := (cAliasSD1)->( GetArea() )
    dbSelectArea(cAliasSD1)
    (cAliasSD1)->( dbGoTop() )
    While !(cAliasSD1)->( Eof() )
        RecLock( (cAliasSD1), .F. )
        (cAliasSD1)->TRB_MARK := IIf( lMarcar, cMarca, '  ' )
        MsUnlock()
        (cAliasSD1)->( dbSkip() )
    EndDo
    RestArea( aAreaSD1 )
Return .T.


/*
______________________________________________________________________________
|_____________________________________________________________________________|
|Programa  - MenuDef    Autor  Fabricio Antunes      Data   22/11/2020   	  |
|_____________________________________________________________________________|
|Descricao|Menu da rotina                                                     |
|         |                                                                   |
|_________|___________________________________________________________________|
|Uso      | Geral                                                         | 
|_________|___________________________________________________________________|
|_____________________________________________________________________________|
*/
Static Function MenuDef()
    Local aRot := {}
    
    ADD OPTION aRot TITLE "Atualizar Preços" ACTION " MsAguarde({|lEnd| GravaDA1(@lEnd)"  OPERATION 6 ACCESS 0
    ADD OPTION aRot TITLE "Imprimir Etiquetas" ACTION "MsAguarde({|lEnd| ImpEtiq(@lEnd) "  OPERATION 6 ACCESS 0
    ADD OPTION aRot TITLE "Atualiza ICM" ACTION "AtuICM()"  OPERATION 6 ACCESS 0
    ADD OPTION aRot TITLE 'Alterar'    ACTION 'VIEWDEF.MFAT001' OPERATION MODEL_OPERATION_UPDATE ACCESS 0 //OPERATION 4


Return(Aclone(aRot))

/*
______________________________________________________________________________
|_____________________________________________________________________________|
|Programa  - MCFG006TIT   Autor  Fabricio Antunes      Data   22/11/2020   	  |
|_____________________________________________________________________________|
|Descricao|Função para criar as colunas do grid                               |
|         |                                                                   |
|_________|___________________________________________________________________|
|Uso      | Geral                                                         | 
|_________|___________________________________________________________________|
|_____________________________________________________________________________|
*/
Static Function MCFG006TIT(cCampo,cTitulo,nArrData,cPicture,nAlign,nSize,nDecimal)
    Local aColumn
    Local bData     := {||}
    Default nAlign     := 1
    Default nSize     := 20
    Default nDecimal:= 0
    Default nArrData:= 0  
        
    If nArrData > 0
        bData := &("{||" + cCampo +"}") //&("{||oBrowse:DataArray[oBrowse:At(),"+STR(nArrData)+"]}")
    EndIf
    
    /* Array da coluna
    [n][01] Título da coluna
    [n][02] Code-Block de carga dos dados
    [n][03] Tipo de dados
    [n][04] Máscara
    [n][05] Alinhamento (0=Centralizado, 1=Esquerda ou 2=Direita)
    [n][06] Tamanho
    [n][07] Decimal
    [n][08] Indica se permite a edição
    [n][09] Code-Block de validação da coluna após a edição
    [n][10] Indica se exibe imagem
    [n][11] Code-Block de execução do duplo clique
    [n][12] Variável a ser utilizada na edição (ReadVar)
    [n][13] Code-Block de execução do clique no header
    [n][14] Indica se a coluna está deletada
    [n][15] Indica se a coluna será exibida nos detalhes do Browse
    [n][16] Opções de carga dos dados (Ex: 1=Sim, 2=Não)
    */
    aColumn := {cTitulo,bData,,cPicture,nAlign,nSize,nDecimal,.F.,{||.T.},.F.,{||.T.},NIL,{||.T.},.F.,.F.,{}}
Return {aColumn}


/*
______________________________________________________________________________
|_____________________________________________________________________________|
|Programa  - GravaDa1   Autor  Fabricio Antunes      Data   22/11/2020   	  |
|_____________________________________________________________________________|
|Descricao|Atualiza Tabela de preços                        |
|         |                                                                   |
|_________|___________________________________________________________________|
|Uso      | Geral                                                         | 
|_________|___________________________________________________________________|
|_____________________________________________________________________________|
*/

Static Function GravaDa1(lEnd)
	(cAliasT)->(dbSetOrder(1))
	(cAliasT)->(dbGoTop() )

	While (cAliasT)->(!Eof())
		if !Empty((cAliasT)->TRB_MARK)
		    //MsProcTxt(alltrim((cAliasT)->B1_DESC))	

			If lEnd .and. MsgYesNo("Confirma Cancelar Atualização de Preços")
				exit
			EndIf

			// pesquisa a tabela de preço e grava valor
			dbSelectArea("DA1")
			DA1->(dbGoto((cAliasT)->DA1_RECNO))
			IF !DA1->(EOF())
				RecLock("DA1",.F.)
				DA1->DA1_PRCVEN := (cAliasT)->PRCSUG
				DA1->(MsUnlock())
			EndIf

			// atualiza o registro no D1_XFRMPRECO informando que preço foi atualizado			
			dbSelectArea("SD1")			
			SD1->(Dbgoto((cAliasT)->D1_RECNO))
			If !SD1->(EOF())			
			/*
			RecLock("SD1",.F.)
			SD1->D1_XFRMPRE := "S"  // grava que já participou da formação de preços
			SD1->(MsUnlock())
			*/
			EndIf
		EndIf
		dbSelectArea(cAliasT)
		(cAliasT)->(DbSkip())
   
	EndDo
     MsgInfo("Preco atualizado com sucesso")
     IF MsgYesNo("Deseja imprimir estiquetas dos precos atualizados")
            ImpEtiq(.F.) 
     EndIF
Return()


/*
______________________________________________________________________________
|_____________________________________________________________________________|
|Programa  - ImpEtiq   Autor  Fabricio Antunes      Data   22/11/2020   	  |
|_____________________________________________________________________________|
|Descricao|Imprime Etiquetas                                                  |
|         |                                                                   |
|_________|___________________________________________________________________|
|Uso      | Geral                                                         | 
|_________|___________________________________________________________________|
|_____________________________________________________________________________|
*/
Static Function ImpEtiq(lEnd)
Local cImp 	:= "ZEBRA"
Local cPort	:= SuperGetMV('MV_XPCOM',.F., "LPT1")
Local nX

	(cAliasT)->(dbSetOrder(1))
	(cAliasT)->(dbGoTop() )

	While (cAliasT)->(!Eof())
		if !Empty((cAliasT)->TRB_MARK)
		    //MsProcTxt(alltrim((cAliasT)->B1_DESC))	

			If lEnd .and. MsgYesNo("Deseja interromper a Impressão de etiquetas?")
				exit
			EndIf

			// pesquisa a tabela de preço e grava valor
			dbSelectArea("DA1")
			DA1->(dbGoto((cAliasT)->DA1_RECNO))
            For nX:=1 to nVias
                U_XImpetiq(cImp,cPort,DA1->DA1_CODPRO,DA1->DA1_PRCVEN,Alltrim(Posicione("SB1",1,xFilial("SB1")+DA1->DA1_CODPRO,"B1_CODBAR")))
            Next
		EndIf
		(cAliasT)->(DbSkip())
	EndDo
    MsgInfo("Etiquetas impressas com sucesso")
Return()

/*
______________________________________________________________________________
|_____________________________________________________________________________|
|Programa  - ModelDef   Autor  Fabricio Antunes      Data   22/11/2020   	  |
|_____________________________________________________________________________|
|Descricao|Modelo de dados MVC para edicao da tabela temporaria               |
|         |                                                                   |
|_________|___________________________________________________________________|
|Uso      | Geral                                                         | 
|_________|___________________________________________________________________|
|_____________________________________________________________________________|
*/
Static Function ModelDef()
    //Criação do objeto do modelo de dados
    Local oModel := Nil
    
    //Criação da estrutura de dados utilizada na interface
    Local oStTRB := FWFormModelStruct():New()

         
    oStTRB:AddTable(cAliasTRB, {'B1_COD', 'B1_DESC','D1_VUNIT','DA1_PRCVEN','B1_MARKUP','PRCSUG','DIFVALOR','DIFPERC'}, "Precificacao")
     
    //Adiciona os campos da estrutura
    oStTRB:AddField(;
        "Codigo",;                                                                                  // [01]  C   Titulo do campo
        "Codigo",;                                                                                  // [02]  C   ToolTip do campo
        "B1_COD",;                                                                                  // [03]  C   Id do Field
        TamSX3('B1_COD')[3],;                                                                       // [04]  C   Tipo do campo
        TamSX3('B1_COD')[1],;                                                                       // [05]  N   Tamanho do campo
        TamSX3('B1_COD')[2],;                                                                       // [06]  N   Decimal do campo
        Nil,;                                                                                       // [07]  B   Code-block de validação do campo
        Nil,;                                                                                       // [08]  B   Code-block de validação When do campo
        {},;                                                                                        // [09]  A   Lista de valores permitido do campo
        .F.,;                                                                                       // [10]  L   Indica se o campo tem preenchimento obrigatório
        FwBuildFeature( STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTRB+"->B1_COD,'')" ),;          // [11]  B   Code-block de inicializacao do campo
        .T.,;                                                                                       // [12]  L   Indica se trata-se de um campo chave
        .F.,;                                                                                       // [13]  L   Indica se o campo pode receber valor em uma operação de update.
        .F.)                                                                                        // [14]  L   Indica se o campo é virtual
  

    oStTRB:AddField(;
        "Descricao",;                                                                                // [01]  C   Titulo do campo
        "Descricao",;                                                                                // [02]  C   ToolTip do campo
        "B1_DESC",;                                                                                  // [03]  C   Id do Field
        TamSX3('B1_DESC')[3],;                                                                       // [04]  C   Tipo do campo
        TamSX3('B1_DESC')[1],;                                                                       // [05]  N   Tamanho do campo
        TamSX3('B1_DESC')[2],;                                                                       // [06]  N   Decimal do campo
        Nil,;                                                                                        // [07]  B   Code-block de validação do campo
        Nil,;                                                                                        // [08]  B   Code-block de validação When do campo
        {},;                                                                                         // [09]  A   Lista de valores permitido do campo
        .F.,;                                                                                        // [10]  L   Indica se o campo tem preenchimento obrigatório
        FwBuildFeature( STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTRB+"->B1_DESC,'')" ),;          // [11]  B   Code-block de inicializacao do campo
        .F.,;                                                                                        // [12]  L   Indica se trata-se de um campo chave
        .F.,;                                                                                        // [13]  L   Indica se o campo pode receber valor em uma operação de update.
        .F.)                                                                                         // [14]  L   Indica se o campo é virtual
  
 oStTRB:AddField(;
        "Preco Compra",;                                                                              // [01]  C   Titulo do campo
        "Preco Compra",;                                                                              // [02]  C   ToolTip do campo
        "D1_VUNIT",;                                                                                  // [03]  C   Id do Field
        TamSX3('D1_VUNIT')[3],;                                                                       // [04]  C   Tipo do campo
        TamSX3('D1_VUNIT')[1],;                                                                       // [05]  N   Tamanho do campo
        TamSX3('D1_VUNIT')[2],;                                                                       // [06]  N   Decimal do campo
        Nil,;                                                                                         // [07]  B   Code-block de validação do campo
        Nil,;                                                                                         // [08]  B   Code-block de validação When do campo
        {},;                                                                                          // [09]  A   Lista de valores permitido do campo
        .F.,;                                                                                         // [10]  L   Indica se o campo tem preenchimento obrigatório
        FwBuildFeature( STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTRB+"->D1_VUNIT,'')" ),;          // [11]  B   Code-block de inicializacao do campo
        .F.,;                                                                                         // [12]  L   Indica se trata-se de um campo chave
        .F.,;                                                                                         // [13]  L   Indica se o campo pode receber valor em uma operação de update.
        .F.)                                                                                          // [14]  L   Indica se o campo é virtual
  


 oStTRB:AddField(;
        "Preco Venda",;                                                                                 // [01]  C   Titulo do campo
        "Preco Venda",;                                                                                 // [02]  C   ToolTip do campo
        "DA1_PRCVEN",;                                                                                  // [03]  C   Id do Field
        TamSX3('DA1_PRCVEN')[3],;                                                                       // [04]  C   Tipo do campo
        TamSX3('DA1_PRCVEN')[1],;                                                                       // [05]  N   Tamanho do campo
        TamSX3('DA1_PRCVEN')[2],;                                                                       // [06]  N   Decimal do campo
        Nil,;                                                                                           // [07]  B   Code-block de validação do campo
        Nil,;                                                                                           // [08]  B   Code-block de validação When do campo
        {},;                                                                                            // [09]  A   Lista de valores permitido do campo
        .F.,;                                                                                           // [10]  L   Indica se o campo tem preenchimento obrigatório
        FwBuildFeature( STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTRB+"->DA1_PRCVEN1,'')" ),;         // [11]  B   Code-block de inicializacao do campo
        .F.,;                                                                                           // [12]  L   Indica se trata-se de um campo chave
        .F.,;                                                                                           // [13]  L   Indica se o campo pode receber valor em uma operação de update.
        .F.)                                                                                            // [14]  L   Indica se o campo é virtual
  


 oStTRB:AddField(;
        "Markup",;                                                                                      // [01]  C   Titulo do campo
        "Markup",;                                                                                      // [02]  C   ToolTip do campo
        "B1_MARKUP",;                                                                                   // [03]  C   Id do Field
        TamSX3('B1_MARKUP')[3],;                                                                        // [04]  C   Tipo do campo
        TamSX3('B1_MARKUP')[1],;                                                                        // [05]  N   Tamanho do campo
        TamSX3('B1_MARKUP')[2],;                                                                        // [06]  N   Decimal do campo
        Nil,;                                                                                           // [07]  B   Code-block de validação do campo
        Nil,;                                                                                           // [08]  B   Code-block de validação When do campo
        {},;                                                                                            // [09]  A   Lista de valores permitido do campo
        .F.,;                                                                                           // [10]  L   Indica se o campo tem preenchimento obrigatório
        FwBuildFeature( STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTRB+"->B1_MARKUP,'')" ),;           // [11]  B   Code-block de inicializacao do campo
        .F.,;                                                                                           // [12]  L   Indica se trata-se de um campo chave
        .F.,;                                                                                           // [13]  L   Indica se o campo pode receber valor em uma operação de update.
        .F.)                                                                                            // [14]  L   Indica se o campo é virtual
  

 oStTRB:AddField(;
        "Aliq ICM",;                                                                                    // [01]  C   Titulo do campo
        "Aliq ICM",;                                                                                    // [02]  C   ToolTip do campo
        "B1_PICM",;                                                                                     // [03]  C   Id do Field
        TamSX3('B1_PICM')[3],;                                                                          // [04]  C   Tipo do campo
        TamSX3('B1_PICM')[1],;                                                                          // [05]  N   Tamanho do campo
        TamSX3('B1_PICM')[2],;                                                                          // [06]  N   Decimal do campo
        Nil,;                                                                                           // [07]  B   Code-block de validação do campo
        Nil,;                                                                                           // [08]  B   Code-block de validação When do campo
        {},;                                                                                            // [09]  A   Lista de valores permitido do campo
        .F.,;                                                                                           // [10]  L   Indica se o campo tem preenchimento obrigatório
        FwBuildFeature( STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTRB+"->B1_PICM,'')" ),;             // [11]  B   Code-block de inicializacao do campo
        .F.,;                                                                                           // [12]  L   Indica se trata-se de um campo chave
        .F.,;                                                                                           // [13]  L   Indica se o campo pode receber valor em uma operação de update.
        .F.)                                                                                            // [14]  L   Indica se o campo é virtual


 oStTRB:AddField(;
        "Preco Sugerido",;                                                                              // [01]  C   Titulo do campo
        "Preco Sugerido",;                                                                              // [02]  C   ToolTip do campo
        "PRCSUG",;                                                                                      // [03]  C   Id do Field
        TamSX3('DA1_PRCVEN')[3],;                                                                       // [04]  C   Tipo do campo
        TamSX3('DA1_PRCVEN')[1],;                                                                       // [05]  N   Tamanho do campo
        TamSX3('DA1_PRCVEN')[2],;                                                                       // [06]  N   Decimal do campo
        Nil,;                                                                                           // [07]  B   Code-block de validação do campo
        Nil,;                                                                                           // [08]  B   Code-block de validação When do campo
        {},;                                                                                            // [09]  A   Lista de valores permitido do campo
        .T.,;                                                                                           // [10]  L   Indica se o campo tem preenchimento obrigatório
        FwBuildFeature( STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTRB+"->PRCSUG,'')" ),;              // [11]  B   Code-block de inicializacao do campo
        .F.,;                                                                                           // [12]  L   Indica se trata-se de um campo chave
        .T.,;                                                                                           // [13]  L   Indica se o campo pode receber valor em uma operação de update.
        .F.)                                                                                            // [14]  L   Indica se o campo é virtual
  


 oStTRB:AddField(;
        "Dif Valor",;                                                                                   // [01]  C   Titulo do campo
        "Diferenca Valor",;                                                                             // [02]  C   ToolTip do campo
        "DIFVALOR",;                                                                                    // [03]  C   Id do Field
        TamSX3('DA1_PRCVEN')[3],;                                                                       // [04]  C   Tipo do campo
        TamSX3('DA1_PRCVEN')[1],;                                                                       // [05]  N   Tamanho do campo
        TamSX3('DA1_PRCVEN')[2],;                                                                       // [06]  N   Decimal do campo
        Nil,;                                                                                           // [07]  B   Code-block de validação do campo
        Nil,;                                                                                           // [08]  B   Code-block de validação When do campo
        {},;                                                                                            // [09]  A   Lista de valores permitido do campo
        .F.,;                                                                                           // [10]  L   Indica se o campo tem preenchimento obrigatório
        FwBuildFeature( STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTRB+"->DIFVALOR,'')" ),;            // [11]  B   Code-block de inicializacao do campo
        .F.,;                                                                                           // [12]  L   Indica se trata-se de um campo chave
        .F.,;                                                                                           // [13]  L   Indica se o campo pode receber valor em uma operação de update.
        .F.)                                                                                            // [14]  L   Indica se o campo é virtual
  


 oStTRB:AddField(;
        "Dif Perc",;                                                                                // [01]  C   Titulo do campo
        "Diferenca Percentual",;                                                                    // [02]  C   ToolTip do campo
        "DIFPERC",;                                                                                 // [03]  C   Id do Field
        TamSX3('DA1_PRCVEN')[3],;                                                                   // [04]  C   Tipo do campo
        12,;                                                                                        // [05]  N   Tamanho do campo
        2,;                                                                                        // [06]  N   Decimal do campo
        Nil,;                                                                                       // [07]  B   Code-block de validação do campo
        Nil,;                                                                                       // [08]  B   Code-block de validação When do campo
        {},;                                                                                        // [09]  A   Lista de valores permitido do campo
        .F.,;                                                                                       // [10]  L   Indica se o campo tem preenchimento obrigatório
        FwBuildFeature( STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTRB+"->DIFPERC,'')" ),;         // [11]  B   Code-block de inicializacao do campo
        .F.,;                                                                                       // [12]  L   Indica se trata-se de um campo chave
        .F.,;                                                                                       // [13]  L   Indica se o campo pode receber valor em uma operação de update.
        .F.)                                                                                        // [14]  L   Indica se o campo é virtual
  
    oStTRB:SetProperty('PRCSUG', MODEL_FIELD_WHEN, { || .T.})
    oStTRB:SetProperty('PRCSUG', MODEL_FIELD_NOUPD,.F.)


    //Instanciando o modelo, não é recomendado colocar nome da user function (por causa do u_), respeitando 10 caracteres
    oModel := MPFormModel():New("zTRBCadM",/*bPre*/, /*bPos*/,/*bCommit*/,/*bCancel*/) 
     
    //Atribuindo formulários para o modelo
    oModel:AddFields("FORMTRB",/*cOwner*/,oStTRB)
     
    //Setando a chave primária da rotina
    oModel:SetPrimaryKey({'B1_COD'})
     
    //Adicionando descrição ao modelo
    oModel:SetDescription("Precificacao" )
     
    //Setando a descrição do formulário
    oModel:GetModel("FORMTRB"):SetDescription("Precificacao")
Return oModel
 
/*
______________________________________________________________________________
|_____________________________________________________________________________|
|Programa  - ViewDef   Autor  Fabricio Antunes      Data   22/11/2020   	  |
|_____________________________________________________________________________|
|Descricao|Visao de dados MVC para montagem da tela da  tabela temporaria     |
|         |                                                                   |
|_________|___________________________________________________________________|
|Uso      | Geral                                                         | 
|_________|___________________________________________________________________|
|_____________________________________________________________________________|
*/
 
Static Function ViewDef()
    Local oModel := FWLoadModel("MFAT001")
    Local oStTRB := FWFormViewStruct():New()
    Local oView := Nil
 



    //Adicionando campos da estrutura
    oStTRB:AddField(;
        "B1_COD",;                  // [01]  C   Nome do Campo
        "01",;                      // [02]  C   Ordem
        "Codigo",;                  // [03]  C   Titulo do campo
        "Codigo",;                  // [04]  C   Descricao do campo
        Nil,;                       // [05]  A   Array com Help
        "C",;                       // [06]  C   Tipo do campo
        "@!",;                      // [07]  C   Picture
        Nil,;                       // [08]  B   Bloco de PictTre Var
        Nil,;                       // [09]  C   Consulta F3
        .F.,;                       // [10]  L   Indica se o campo é alteravel
        Nil,;                       // [11]  C   Pasta do campo
        Nil,;                       // [12]  C   Agrupamento do campo
        Nil,;                       // [13]  A   Lista de valores permitido do campo (Combo)
        Nil,;                       // [14]  N   Tamanho maximo da maior opção do combo
        Nil,;                       // [15]  C   Inicializador de Browse
        Nil,;                       // [16]  L   Indica se o campo é virtual
        Nil,;                       // [17]  C   Picture Variavel
        Nil)                        // [18]  L   Indica pulo de linha após o campo
    oStTRB:AddField(;
        "B1_DESC",;                 // [01]  C   Nome do Campo
        "02",;                      // [02]  C   Ordem
        "Descricao",;               // [03]  C   Titulo do campo
        "Descricao",;               // [04]  C   Descricao do campo
        Nil,;                       // [05]  A   Array com Help
        "C",;                       // [06]  C   Tipo do campo
        "@!",;                      // [07]  C   Picture
        Nil,;                       // [08]  B   Bloco de PictTre Var
        Nil,;                       // [09]  C   Consulta F3
        .F.,;                       // [10]  L   Indica se o campo é alteravel
        Nil,;                       // [11]  C   Pasta do campo
        Nil,;                       // [12]  C   Agrupamento do campo
        Nil,;                       // [13]  A   Lista de valores permitido do campo (Combo)
        Nil,;                       // [14]  N   Tamanho maximo da maior opção do combo
        Nil,;                       // [15]  C   Inicializador de Browse
        Nil,;                       // [16]  L   Indica se o campo é virtual
        Nil,;                       // [17]  C   Picture Variavel
        Nil)                        // [18]  L   Indica pulo de linha após o campo
    oStTRB:AddField(;
        "D1_VUNIT",;                // [01]  C   Nome do Campo
        "03",;                      // [02]  C   Ordem
        "Preco de Compra",;         // [03]  C   Titulo do campo
        "Preco de Compra",;         // [04]  C   Descricao do campo
        Nil,;                       // [05]  A   Array com Help
        "N",;                       // [06]  C   Tipo do campo
        "@E 9,999,999.99",;         // [07]  C   Picture
        Nil,;                       // [08]  B   Bloco de PictTre Var
        Nil,;                       // [09]  C   Consulta F3
        .F.,;                       // [10]  L   Indica se o campo é alteravel
        Nil,;                       // [11]  C   Pasta do campo
        Nil,;                       // [12]  C   Agrupamento do campo
        Nil,;                       // [13]  A   Lista de valores permitido do campo (Combo)
        Nil,;                       // [14]  N   Tamanho maximo da maior opção do combo
        Nil,;                       // [15]  C   Inicializador de Browse
        Nil,;                       // [16]  L   Indica se o campo é virtual
        Nil,;                       // [17]  C   Picture Variavel
        Nil)                        // [18]  L   Indica pulo de linha após o campo
    oStTRB:AddField(;
        "DA1_PRCVEN",;              // [01]  C   Nome do Campo
        "04",;                      // [02]  C   Ordem
        "Preco de Venda",;          // [03]  C   Titulo do campo
        "Preco de Venda",;          // [04]  C   Descricao do campo
        Nil,;                       // [05]  A   Array com Help
        "N",;                       // [06]  C   Tipo do campo
        "@E 9,999,999.99",;         // [07]  C   Picture
        Nil,;                       // [08]  B   Bloco de PictTre Var
        Nil,;                       // [09]  C   Consulta F3
        .F.,;                       // [10]  L   Indica se o campo é alteravel
        Nil,;                       // [11]  C   Pasta do campo
        Nil,;                       // [12]  C   Agrupamento do campo
        Nil,;                       // [13]  A   Lista de valores permitido do campo (Combo)
        Nil,;                       // [14]  N   Tamanho maximo da maior opção do combo
        Nil,;                       // [15]  C   Inicializador de Browse
        Nil,;                       // [16]  L   Indica se o campo é virtual
        Nil,;                       // [17]  C   Picture Variavel
        Nil)                        // [18]  L   Indica pulo de linha após o campo

    oStTRB:AddField(;
        "B1_MARKUP",;               // [01]  C   Nome do Campo
        "05",;                      // [02]  C   Ordem
        "Markup",;                  // [03]  C   Titulo do campo
        "Markup",;                  // [04]  C   Descricao do campo
        Nil,;                       // [05]  A   Array com Help
        "N",;                       // [06]  C   Tipo do campo
        "@E 9,999,999.99",;         // [07]  C   Picture
        Nil,;                       // [08]  B   Bloco de PictTre Var
        Nil,;                       // [09]  C   Consulta F3
        .F.,;                       // [10]  L   Indica se o campo é alteravel
        Nil,;                       // [11]  C   Pasta do campo
        Nil,;                       // [12]  C   Agrupamento do campo
        Nil,;                       // [13]  A   Lista de valores permitido do campo (Combo)
        Nil,;                       // [14]  N   Tamanho maximo da maior opção do combo
        Nil,;                       // [15]  C   Inicializador de Browse
        Nil,;                       // [16]  L   Indica se o campo é virtual
        Nil,;                       // [17]  C   Picture Variavel
        Nil)                        // [18]  L   Indica pulo de linha após o campo

    oStTRB:AddField(;
        "B1_PICM",;               // [01]  C   Nome do Campo
        "06",;                      // [02]  C   Ordem
        "Aliq ICM",;                  // [03]  C   Titulo do campo
        "Aliq ICM",;                  // [04]  C   Descricao do campo
        Nil,;                       // [05]  A   Array com Help
        "N",;                       // [06]  C   Tipo do campo
        "@E 9,999,999.99",;         // [07]  C   Picture
        Nil,;                       // [08]  B   Bloco de PictTre Var
        Nil,;                       // [09]  C   Consulta F3
        .F.,;                       // [10]  L   Indica se o campo é alteravel
        Nil,;                       // [11]  C   Pasta do campo
        Nil,;                       // [12]  C   Agrupamento do campo
        Nil,;                       // [13]  A   Lista de valores permitido do campo (Combo)
        Nil,;                       // [14]  N   Tamanho maximo da maior opção do combo
        Nil,;                       // [15]  C   Inicializador de Browse
        Nil,;                       // [16]  L   Indica se o campo é virtual
        Nil,;                       // [17]  C   Picture Variavel
        Nil)                        // [18]  L   Indica pulo de linha após o campo

    oStTRB:AddField(;
        "PRCSUG",;                  // [01]  C   Nome do Campo
        "07",;                      // [02]  C   Ordem
        "Preco Sugerido",;          // [03]  C   Titulo do campo
        "Preco Sugerido",;          // [04]  C   Descricao do campo
        Nil,;                       // [05]  A   Array com Help
        "N",;                       // [06]  C   Tipo do campo
        "@E 9,999,999.99",;         // [07]  C   Picture
        Nil,;                       // [08]  B   Bloco de PictTre Var
        Nil,;                       // [09]  C   Consulta F3
        .T.,;                       // [10]  L   Indica se o campo é alteravel
        Nil,;                       // [11]  C   Pasta do campo
        Nil,;                       // [12]  C   Agrupamento do campo
        Nil,;                       // [13]  A   Lista de valores permitido do campo (Combo)
        Nil,;                       // [14]  N   Tamanho maximo da maior opção do combo
        Nil,;                       // [15]  C   Inicializador de Browse
        Nil,;                       // [16]  L   Indica se o campo é virtual
        Nil,;                       // [17]  C   Picture Variavel
        Nil)                        // [18]  L   Indica pulo de linha após o campo

    oStTRB:AddField(;
        "DIFVALOR",;                // [01]  C   Nome do Campo
        "08",;                      // [02]  C   Ordem
        "Dif Valor",;               // [03]  C   Titulo do campo
        "Dif Valor",;               // [04]  C   Descricao do campo
        Nil,;                       // [05]  A   Array com Help
        "N",;                       // [06]  C   Tipo do campo
        "@E 9,999,999.99",;         // [07]  C   Picture
        Nil,;                       // [08]  B   Bloco de PictTre Var
        Nil,;                       // [09]  C   Consulta F3
        .F.,;                       // [10]  L   Indica se o campo é alteravel
        Nil,;                       // [11]  C   Pasta do campo
        Nil,;                       // [12]  C   Agrupamento do campo
        Nil,;                       // [13]  A   Lista de valores permitido do campo (Combo)
        Nil,;                       // [14]  N   Tamanho maximo da maior opção do combo
        Nil,;                       // [15]  C   Inicializador de Browse
        Nil,;                       // [16]  L   Indica se o campo é virtual
        Nil,;                       // [17]  C   Picture Variavel
        Nil)                        // [18]  L   Indica pulo de linha após o campo

    oStTRB:AddField(;
        "DIFPERC",;                 // [01]  C   Nome do Campo
        "09",;                      // [02]  C   Ordem
        "Dif Percent",;             // [03]  C   Titulo do campo
        "Dif Percent",;             // [04]  C   Descricao do campo
        Nil,;                       // [05]  A   Array com Help
        "N",;                       // [06]  C   Tipo do campo
        "@E 9,999,999.99",;         // [07]  C   Picture
        Nil,;                       // [08]  B   Bloco de PictTre Var
        Nil,;                       // [09]  C   Consulta F3
        .F.,;                       // [10]  L   Indica se o campo é alteravel
        Nil,;                       // [11]  C   Pasta do campo
        Nil,;                       // [12]  C   Agrupamento do campo
        Nil,;                       // [13]  A   Lista de valores permitido do campo (Combo)
        Nil,;                       // [14]  N   Tamanho maximo da maior opção do combo
        Nil,;                       // [15]  C   Inicializador de Browse
        Nil,;                       // [16]  L   Indica se o campo é virtual
        Nil,;                       // [17]  C   Picture Variavel
        Nil)                        // [18]  L   Indica pulo de linha após o campo
     
    //Criando a view que será o retorno da função e setando o modelo da rotina
    oView := FWFormView():New()
    oView:SetModel(oModel)
     
    //Atribuindo formulários para interface
    oView:AddField("VIEW_TRB", oStTRB, "FORMTRB")
     
    //Criando um container com nome tela com 100%
    oView:CreateHorizontalBox("TELA",100)
     
    //Colocando título do formulário
    oView:EnableTitleView('VIEW_TRB', 'Precificacao' )  
     
    //Força o fechamento da janela na confirmação
    oView:SetCloseOnOk({||.T.})
     
    //O formulário da interface será colocado dentro do container
    oView:SetOwnerView("VIEW_TRB","TELA")
Return oView

/*
______________________________________________________________________________
|_____________________________________________________________________________|
|Programa  - AtuICM   Autor  Fabricio Antunes      Data   22/11/2020   	      |
|_____________________________________________________________________________|
|Descricao|Funcao para atualizacao de aliquota de ICMS                        |
|         |                                                                   |
|_________|___________________________________________________________________|
|Uso      | Geral                                                         | 
|_________|___________________________________________________________________|
|_____________________________________________________________________________|
*/

Static Function AtuICM
Local nICM:=0

TRB->(dbGoTop())
dbSelectArea("SB1")
SB1->((dbSetOrder(1)))

dbSelectArea("SF4")
SF4->(dbSetOrder(1))

While !TRB->(EOF())

    IF SB1->(dbSeek(xFilial("SB1")+TRB->B1_COD))
        IF SB1->B1_PICM <> 0
            nICM    :=SB1->B1_PICM
        Else
            nICM    :=GetMv("MV_ICMPAD")
        EndIF
        IF SF4->(dbSeek(xFilial('SF4')+SB1->B1_TS))
            IF SF4->F4_ICM <> 'S'
                nICM:=0
            EndIF
        EndIF
        RecLock("TRB",.F.)
            TRB->B1_PICM    :=nICM
            TRB->PRCSUG     :=Round((TRB->D1_VUNIT/((TRB->B1_MARKUP+nICM-100)/100))*-1,2)
            TRB->DIFVALOR   :=Round(((TRB->D1_VUNIT/((TRB->B1_MARKUP+nICM-100)/100))*-1)-TRB->DA1_PRCVEN,2)
            TRB->DIFPERC    :=Round((((TRB->D1_VUNIT/((TRB->B1_MARKUP+nICM-100)/100))*-1)/TRB->DA1_PRCVEN*100)-100,2)
        msUnLock()
    EndIF
    TRB->(dbSkip())
EndDO


Return
