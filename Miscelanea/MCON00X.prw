#INCLUDE "PROTHEUS.CH"
#INCLUDE "FWMVCDEF.CH"
#include 'stdwin.ch'

/*
______________________________________________________________________________
|_____________________________________________________________________________|
|Programa  - MCON001    Autor  Fabricio Antunes      Data   22/09/2021   	  |
|_____________________________________________________________________________|
|Descricao|Funcao de conciliacao financeiro                                   |
|         |                                                                   |
|_________|___________________________________________________________________|
|Uso      |                                                                  | 
|_________|___________________________________________________________________|
|_____________________________________________________________________________|
*/

User Function MCON00X()
    Local aCposCab    := {}
    Local aCposGrd1   := {}
	Local aCposGrd2	  := {}
	Local aPergs   := {}
    Local aTitulos
    Local nX
	Local cSpace:="                 "
    Private cTableCab, cTableGr1, cTableGr2
	Private oBrowse := Nil	
    Private aRotina         := Menudef()
    Private aBrows, aGrd1, aGrd2    //Varias com estrutura de colunas para ser utilizado no browser, no fields e nos grids
    Private cAlisCab:=GetNextAlias()
    Private cAlisGr1:=GetNextAlias()
    Private cAlisGr2:=GetNextAlias()
    Private cfilqry
	Private aSelFil := {}
	Private oGrd1
    Private oGrd2
    Private oCabec
        aPergs:={}

        // Perguntas de parametros para Funcao
        aAdd(aPergs, {1, "Da Conta", '           ',  "@!", ".T.", "CT1", ".T.", 80,  .T.})
        aAdd(aPergs, {1, "Registro de",   sTod('        '),  "", ".T.", "", ".T.", 80,  .T.})
        aAdd(aPergs, {1, "Registros ate",  sTod('        '),  "", ".T.", "", ".T.", 80,  .T.})
        aAdd(aPergs ,{3, "Seleciona Filiais",1,{"Sim","Nao"},50,"",.T.}) 
        aAdd(aPergs ,{3, "Somente Divergentes",2,{"Sim","Nao"},50,"",.T.}) 
        aAdd(aPergs ,{3, "Somente Div. Sld Final",2,{"Sim","Nao"},50,"",.T.}) 
        aAdd(aPergs, {1, "Do Item", cSpace,  "@!", ".T.", "CTD", ".T.", 80,  .F.})
        aAdd(aPergs, {1, "Ate o Item", 'ZZZZZZZZZZZZZZZZZ',  "@!", ".T.", "CTD", ".T.", 80,  .F.})

        If ParamBox(aPergs, "Informe os parâmetros para definicao dos filtros da rotina")
           

               //----------------------------------------------------------
            //Cria tabela para browser que sera usada no filds do MVC
            //----------------------------------------------------------
            aAdd(aCposCab,{"ID","C",6,00})
           	aAdd(aCposCab,{"ITEM_TAB","C",10,00})
            aAdd(aCposCab,{"DESC_ITEM","C",30,00})
            aAdd(aCposCab,{"FIN_SLA","N",15,2})
            aAdd(aCposCab,{"FIN_DEB","N",15,2})
            aAdd(aCposCab,{"FIN_CRE","N",15,2})
            aAdd(aCposCab,{"FIN_SLF","N",15,2})
            aAdd(aCposCab,{"CTB_SLA","N",15,2})
            aAdd(aCposCab,{"CTB_DEB","N",15,2})
            aAdd(aCposCab,{"CTB_CRE","N",15,2})
            aAdd(aCposCab,{"CTB_SLF","N",15,2})
            aAdd(aCposCab,{"DEF_TAB","C",1,0})
            aAdd(aCposCab,{"DIF_VAL","N",15,2})
           
            //Array com nome dos campos para Browser
            aTitulos:={'ID Rotina', "Codigo", "Nome", "Fin. Sl. Ant.","Fin. Debito","Fin. Credito","Fin. Sl. Fin.","Ctb. Sl. Ant." ,"Ctb. Debito","Ctb. Credito" ,"Ctb. Sl. Fin.", "Div.", "Diferença" }

            //Funcao para gerar as colunas do Browser
            aBrows:=gerCpBrow(aCposCab,aTitulos)
            If oCabec <> Nil
                oCabec:Delete()
                oCabec := Nil
            Endif
            oCabec:=FWTemporaryTable():New(cAlisCab)
            oCabec:SetFields(aCposCab)
	        oCabec:AddIndex("1", {"ID"})
            oCabec:AddIndex("2", {"ITEM_TAB"})
            oCabec:Create()
            
            //Obtenho o nome "verdadeiro" da tabela no BD (criada como tempor ria)
	        cTableCab := oCabec:GetRealName()



            //----------------------------------------------------------
            //Cria tabela grid 1 para ser usado  do MVC
            //----------------------------------------------------------

            If oGrd1 <> Nil
                oGrd1:Delete()
                oGrd1 := Nil
            Endif

	        oGrd1 := FWTemporaryTable():New(cAlisGr1)
            
            aAdd(aCposGrd1,{"ID"        ,"C",06,0})
            aAdd(aCposGrd1,{"ITEM"      ,"C",03,0})
            aAdd(aCposGrd1,{"DATS"      ,"C",10,0})
            aAdd(aCposGrd1,{"DOC"       ,"C",09,0})
            aAdd(aCposGrd1,{"HIST"      ,"C",50,0})
            aAdd(aCposGrd1,{"FIN_DEB"   ,"N",18,2})
            aAdd(aCposGrd1,{"FIN_CRED"  ,"N",18,2})
            aAdd(aCposGrd1,{"SALDO"     ,"N",18,2})
    
            aTitulos:={'ID Rotina',  "Item","Data", "Documento", "Historico","Fin. Debito","Fin. Credito", "Saldo" }
            aGrd1:=gerCpBrow(aCposGrd1,aTitulos)


            oGrd1:SetFields(aCposGrd1)
            oGrd1:AddIndex("1", {"ID"})
            oGrd1:AddIndex("2", {"DATS"})
            oGrd1:AddIndex("3", {"DOC"})
            oGrd1:Create()
            //Obtenho o nome "verdadeiro" da tabela no BD (criada como tempor ria)
            cTableGr1 := oGrd1:GetRealName()


            //----------------------------------------------------------
            //Cria tabela grid 2 para ser usado  do MVC
            //----------------------------------------------------------

            If oGrd2 <> Nil
                oGrd2:Delete()
                oGrd2 := Nil
            Endif

	        oGrd2 := FWTemporaryTable():New(cAlisGr2)

            aAdd(aCposGrd2,{"ID"        ,"C",06,0})
            aAdd(aCposGrd2,{"ITEM"      ,"C",03,0})
            aAdd(aCposGrd2,{"DATS"      ,"C",10,0})
            aAdd(aCposGrd2,{"LOTE"      ,"C",09,0})
            aAdd(aCposGrd2,{"HIST"      ,"C",50,0})
            aAdd(aCposGrd2,{"FIN_DEB"   ,"N",18,2})
            aAdd(aCposGrd2,{"FIN_CRED"  ,"N",18,2})
            aAdd(aCposGrd2,{"SALDO"     ,"N",18,2})
    
            aTitulos:={'ID Rotina', "Item","Data", "Lote", "Historico","Fin. Debito","Fin. Credito", "Saldo" }
            aGrd2:=gerCpBrow(aCposGrd2,aTitulos)


            oGrd2:SetFields(aCposGrd2)
            oGrd2:AddIndex("1", {"ID"})
            oGrd2:AddIndex("2", {"DATS"})
            oGrd2:AddIndex("3", {"LOTE"})
            oGrd2:Create()
            //Obtenho o nome "verdadeiro" da tabela no BD (criada como tempor ria)
            cTableGr2 := oGrd2:GetRealName()

            //----------------------------------------------------------
            //Preenchimento dos dados nas tabelas
            //----------------------------------------------------------
            If MV_PAR04 == 1 .And. Len( aSelFil ) <= 0
                aSelFil := AdmGetFil()
                If Len( aSelFil ) <= 0
                    Return .F.
                EndIf
                cfilqry := "("
                For nX := 1 to len(aSelFil)
                    cfilqry += "'"+aSelFil[nX]+"',"
                Next
                cfilqry := substr(cfilqry,1,len(cfilqry)-1) + ")"
            EndIf

            MsgRun("Carregando dados de movimentação financeira...",,{||CursorWait(),GrvFin(MV_PAR01),CursorArrow()})

			
			dbSelectArea(cAlisGr1)
			dbSelectArea(cAlisGr2)

            //----------------------------------------------------------
            //Montagem do browser
            //----------------------------------------------------------
            oBrowse:= FwMBrowse():New()
            oBrowse:SetDescription("Concilicao Financeira") 
            oBrowse:SetAlias(cAlisCab) 
            oBrowse:SetWalkThru(.F.)
            oBrowse:SetAmbiente(.T.) 
            oBrowse:SetTemporary(.T.)
            oBrowse:SetFields(aBrows)
			oBrowse:AddLegend( "DIF_VAL == 0", "GREEN", "Correto" )
			oBrowse:AddLegend( "DIF_VAL <> 0", "RED",   "Incorreto" )
            oBrowse:Activate()

            //--------------------------------
            //Exclui tabelas temporarias
            //--------------------------------
            If oCabec <> Nil
                oCabec:Delete()
                oCabec := Nil
            Endif

            If oGrd1 <> Nil
                oGrd1:Delete()
                oGrd1 := Nil
            Endif

            If oGrd2 <> Nil
                oGrd2:Delete()
                oGrd2 := Nil
            Endif
        EndIF
Return


/*
______________________________________________________________________________
|_____________________________________________________________________________|
|Programa  - MenuDef    Autor  Fabricio Antunes      Data   22/11/2020   	  |
|_____________________________________________________________________________|
|Descricao|Menu da rotina                                                     |
|         |                                                                   |
|_________|___________________________________________________________________|
|Uso      |                                                                  | 
|_________|___________________________________________________________________|
|_____________________________________________________________________________|
*/
Static Function MenuDef()
    Local aRot := {}
    
    ADD OPTION aRot TITLE 'Detalhes'    ACTION 'VIEWDEF.MCON001'OPERATION 4 ACCESS 0 
	ADD OPTION aRot TITLE 'Relatorio'    ACTION 'U_MCON01A()' OPERATION 4 ACCESS 0 

Return(Aclone(aRot))

/*
______________________________________________________________________________
|_____________________________________________________________________________|
|Programa  - ModelDef   Autor  Fabricio Antunes      Data   22/11/2020   	  |
|_____________________________________________________________________________|
|Descricao|Modelo de dados MVC para edicao da tabela temporaria               |
|         |                                                                   |
|_________|___________________________________________________________________|
|Uso      |                                                                  | 
|_________|___________________________________________________________________|
|_____________________________________________________________________________|
*/
Static Function ModelDef()

	Local oModel := Nil
	Local osCabec := FWFormModelStruct():New()
	Local osGrd1  := FWFormModelStruct():New()
	Local osGrd2  := FWFormModelStruct():New()
	Local nX
	Local bPre := {|oModel, cAction, cIDField, xValue| validPre(oModel, cAction, cIDField, xValue)}
	Local bPos := {|oModel|fieldValidPos(oModel)}
	Local bLoad := {|oModel, lCopy| loadField(oModel, lCopy)}
	Local bLoaGr1	:={|oModel, lCopy| loadGrd(oModel, lCopy,"GR1")}
	Local bLoaGr2	:={|oModel, lCopy| loadGrd(oModel, lCopy,"GR2")}

	For nX:=1 to Len(aBrows)
		aBrows[nX,6]=.F.
	Next
	osCabec:AddTable(cAlisCab, {"ID"}, "Concilicao Financeira")

	For nX:=1 to Len(aGrd1)
		aadd(aGrd1[nX],.F.)
	Next

	For nX:=1 to Len(aGrd2)
	 	aadd(aGrd2[nX],.F.)
	Next

    /*----------------------------------------------------------------------
    Estratuda do array para montagem dos campos usados na funcao MntStrut
        1 - Descricao
        2 - Nome do Campo
        3 - Tipo do campo
        4 - Tamanho do campo
        5 - Decimal
        6 - Se campo e editavel
    ------------------------------------------------------------------------*/

     MntStrut(@osCabec,cAlisCab,aBrows)  
     MntStrut(@osGrd1,cAlisGr1,aGrd1)  
     MntStrut(@osGrd2,cAlisGr2,aGrd2)  

    osCabec:AddTable(cAlisCab,, "Concilicao Financeira"	,{|| oCabec:GetRealName()})
	osGrd1:AddTable(cAlisGr1,, "Concilicao Financeira"	,{|| oGrd1:GetRealName()})
	osGrd2:AddTable(cAlisGr2,, "Contabilidade"			,{|| oGrd2:GetRealName()})	

    oModel := FWFormModel():New( 'mdMCON001',,,{|oModel| commit()},{|oModel| cancel()})   

    
	oModel:AddFields( 'ID_M_FLD', , osCabec,bPre,bPos,bLoad)
	//oModel:AddGrid( 'ID_M_GRD1', 'ID_M_FLD', osGrd1)
    //oModel:AddGrid( 'ID_M_GRD2', 'ID_M_FLD', osGrd2)
	oModel:AddGrid( 'ID_M_GRD1', 'ID_M_FLD', osGrd1, /*bLinePre*/, /*{|oModelZA2| ValLinha(oModelZA2)}*/, /*bPreVal*/,/*{|oModel| ValLinha(oModel)}*/, bLoaGr1/*bLoad1*/)
    oModel:AddGrid( 'ID_M_GRD2', 'ID_M_FLD', osGrd2, /*bLinePre*/, /*{|oModelZA2| ValLinha(oModelZA2)}*/, /*bPreVal*/,/*{|oModel| ValLinha(oModel)}*/, bLoaGr2/* bLoad2*/)

	oModel:SetRelation( 'ID_M_GRD1', {{'ID','ID'}}, (cAlisGr1)->(IndexKey(1)))
    oModel:SetRelation( 'ID_M_GRD2', {{'ID','ID'}}, (cAlisGr2)->(IndexKey(1)))

	oModel:GetModel( 'ID_M_GRD1' ):SetUniqueLine( { 'ITEM'} )
	oModel:GetModel( 'ID_M_GRD2' ):SetUniqueLine( { 'ITEM'} )
	oModel:SetPrimaryKey({ 'ID' })

	oModel:AddCalc( 'TOTAL', 'ID_M_FLD', 'ID_M_GRD1',  'SALDO'	, '_nVlrOcor', 'SUM' , ,,'Total Saldo',/*{ |oModel| AGL300H( oModel)} */  )
	oModel:AddCalc( 'TOTAL2', 'ID_M_FLD', 'ID_M_GRD2', 'SALDO'	, '_nVlrOco2', 'SUM' , ,,'Total Saldo',/*{ |oModel| AGL300H( oModel)} */  )

	oModel:SetDescription( 'Conciliacao Financeiro' )
	oModel:GetModel( 'ID_M_GRD1' ):SetDescription( 'Contabilidade' )
    oModel:GetModel( 'ID_M_GRD1' ):SetDescription( 'Financeiro' )
	

Return oModel

/*
______________________________________________________________________________
|_____________________________________________________________________________|
|Programa  - ModelDef   Autor  Fabricio Antunes      Data   22/11/2020   	  |
|_____________________________________________________________________________|
|Descricao|Funcao de validacao pos carregamento dos dados                     |
|         |                                                                   |
|_________|___________________________________________________________________|
|Uso      |                                                                  | 
|_________|___________________________________________________________________|
|_____________________________________________________________________________|
*/
Static Function fieldValidPos(oModel)
Local lRet := .T.
   
   	aAdd(aCposGrd1,{"ID"        ,"C",06,0})
	aAdd(aCposGrd1,{"ITEM"      ,"C",03,0})
	
   	aAdd(aCposGrd2,{"ID"        ,"C",06,0})
	aAdd(aCposGrd2,{"ITEM"      ,"C",03,0})
	

      oModel:GetModel():SetErrorMessage('mdMCON001', "ID" , 'mdMCON001' , 'ID' , "ITEM")      
   
Return lRet

/*
______________________________________________________________________________
|_____________________________________________________________________________|
|Programa  - validPre   Autor  Fabricio Antunes      Data   22/11/2020   	  |
|_____________________________________________________________________________|
|Descricao|Funcao de validação dos dados de carregamento                      |
|         |                                                                   |
|_________|___________________________________________________________________|
|Uso      |                                                                  | 
|_________|___________________________________________________________________|
|_____________________________________________________________________________|
*/
Static Function validPre(oModel, cAction, cIDField, xValue)
Local lRet := .T.

   oModel:GetModel():SetErrorMessage('mdMCON001', "ID" , 'mdMCON001' , 'ID' , "ITEM")
Return

Return lRet

/*
______________________________________________________________________________
|_____________________________________________________________________________|
|Programa  - loadField   Autor  Fabricio Antunes      Data   22/11/2020   	  |
|_____________________________________________________________________________|
|Descricao|Funcao de carregamento dos dados para o Filds                       |
|         |                                                                   |
|_________|___________________________________________________________________|
|Uso      |                                                                  | 
|_________|___________________________________________________________________|
|_____________________________________________________________________________|
*/

Static Function loadField(oModel, lCopy)
Local aLoad := {}
Local nI as numeric
Local aLine as array
Local xValue as variant

//    aAdd(aLoad, {xFilial("01"), "ID", "ITEM"}) //dados

	aLine := {}
	//DbSelectArea(cAlisCab)

//	While !(cAlisCab)->(EOF())
		For nI := 1 to Len(aBrows)
			If aBrows[nI][3] == "C"
				xValue := (cAlisCab)->&(aBrows[nI,2])
			Elseif aBrows[nI][3] == "D"
				xValue := StoD((cAlisCab)->&(aBrows[nI,2]))
			Elseif aBrows[nI][3] == "N"
				xValue := (cAlisCab)->&(aBrows[nI,2])
			Else
				xValue := .F.
			Endif

			aAdd(aLine, xValue)
		Next
	

	aAdd(aLoad, aLine) //dados
	aAdd(aLoad, 1) //recno
      
Return aLoad

/*
______________________________________________________________________________
|_____________________________________________________________________________|
|Programa  - Commit   Autor  Fabricio Antunes      Data   22/11/2020     	  |
|_____________________________________________________________________________|
|Descricao|Funcao de valicao do comit da					  tela            |
|         |                                                                   |
|_________|___________________________________________________________________|
|Uso      |                                                                  | 
|_________|___________________________________________________________________|
|_____________________________________________________________________________|
*/
Static Function Commit()
Return .T.
/*
______________________________________________________________________________
|_____________________________________________________________________________|
|Programa  - Cancel   Autor  Fabricio Antunes      Data   22/11/2020   	      |
|_____________________________________________________________________________|
|Descricao|Funcao de valicao do cancelamento do tela                          |
|         |                                                                   |
|_________|___________________________________________________________________|
|Uso      |                                                                  | 
|_________|___________________________________________________________________|
|_____________________________________________________________________________|
*/

Static Function Cancel()
Return .T.
/*
______________________________________________________________________________
|_____________________________________________________________________________|
|Programa  - ViewDef   Autor  Fabricio Antunes      Data   21/09/2021   	  |
|_____________________________________________________________________________|
|Descricao|Visao de dados MVC para montagem da tela da  tabela temporaria     |
|         |                                                                   |
|_________|___________________________________________________________________|
|Uso      |                                                                  | 
|_________|___________________________________________________________________|
|_____________________________________________________________________________|
*/

Static Function ViewDef()
	Local oModel := FWLoadModel("MCON001")
	Local osCabec := FWFormViewStruct():New()
	Local osGrd1 := FWFormViewStruct():New()
	Local osGrd2 := FWFormViewStruct():New()
	Local oView := Nil
	Local nX
	Local aDadCab :={}
	Local aDadGr1 :={}
	Local aDadGr2 :={}
    /*----------------------------------------------------------------------
    Estratuda do array para montagem dos campos usados na funcao MntView
        1 - Nome do Campo
        2 - Ordem
        3 - Titulo do campo
        4 - Tipo do campo
        5 - Picture
        6 - Se campo e editavel
    ------------------------------------------------------------------------*/
  
	For nX:=1 to Len(aBrows)
		IF aBrows[nX,3] = "C"
            cPict:="@!"
		ElseIF aBrows[nX,3] = "N"
            cPict:="@E 9,999,999.99"
		Else
            cPict:=""
		EnDIF
        aADD(aDadCab,{aBrows[nX,2],StrZero(nX,2),aBrows[nX,1],aBrows[nX,3],cPict,.F.})

	Next

	For nX:=1 to Len(aGrd1)
		IF aGrd1[nX,3] = "C"
            cPict:="@!"
		ElseIF aGrd1[nX,3] = "N"
            cPict:="@E 9,999,999.99"
		Else
            cPict:=""
		EnDIF
        aADD(aDadGr1,{aGrd1[nX,2],StrZero(nX,2),aGrd1[nX,1],aGrd1[nX,3],cPict,.F.})

	Next

	For nX:=1 to Len(aGrd2)
	 	IF aGrd2[nX,3] = "C"
             cPict:="@!"
	 	ElseIF aGrd2[nX,3] = "N"
             cPict:="@E 9,999,999.99"
	 	Else
             cPict:=""
	 	EnDIF
        aADD(aDadGr2,{aGrd2[nX,2],StrZero(nX,2),aGrd2[nX,1],aGrd2[nX,3],cPict,.F.})

	Next

    MntView(@osCabec,aDadCab)
    MntView(@osGrd1,aDadGr1)
     MntView(@osGrd2,aDadGr2)

    oView := FWFormView():New()
    oView:SetModel(oModel)

    oView:AddField("ID_V_FLD", osCabec, "ID_M_FLD")
    oView:AddGrid("ID_V_GRD1", osGrd1, "ID_M_GRD1")
    oView:AddGrid("ID_V_GRD2", osGrd2, "ID_M_GRD2")     

    oView:CreateHorizontalBox("SUPERIOR",30)
    oView:CreateHorizontalBox("INFERIOR",70)
    oView:CreateVerticalBox('ESQUERDA', 50 , 'INFERIOR')
	oView:CreateVerticalBox("DIREITA",  50 , 'INFERIOR')
    
    oView:SetOwnerView( 'ID_V_FLD'   , 'SUPERIOR' )
	oView:SetOwnerView( 'ID_V_GRD1'   , 'ESQUERDA' )
	oView:SetOwnerView( 'ID_V_GRD2'   , 'DIREITA' )


    //Colocando título do formulário
    oView:EnableTitleView('ID_V_FLD', 'Conciliacao Financeiro' )  
    oView:EnableTitleView('ID_V_GRD1', 'Contabilidade' )  
     oView:EnableTitleView('ID_V_GRD2', 'Financeiro' )       
    oView:SetCloseOnOk({||.T.})
     
Return oView



/*
______________________________________________________________________________
|_____________________________________________________________________________|
|Programa  - gerCpBrow    Autor  Fabricio Antunes      Data   21/09/2021   	  |
|_____________________________________________________________________________|
|Descricao|Funcao para montar array com colunas para browser                  |
|         |                                                                   |
|_________|___________________________________________________________________|
|Uso      |                                                                  | 
|_________|___________________________________________________________________|
|_____________________________________________________________________________|
*/
Static Function gerCpBrow(aCampos,aTitulos)

	Local nX
	Local aBrows:={}

	For nX:=1 to Len(aCampos)
		AAdd(aBrows,{aTitulos[nX], aCampos[nX,1] ,aCampos[nX,2] ,aCampos[nX,3] ,aCampos[nX,4]})
	Next
Return aBrows

/*
______________________________________________________________________________
|_____________________________________________________________________________|
|Programa  - MntStrut   Autor  Fabricio Antunes      Data   22/11/2020   	  |
|_____________________________________________________________________________|
|Descricao|Funcao para montar estrutura de dados para MODELDEF                |
|         |                                                                   |
|_________|___________________________________________________________________|
|Uso      |                                                                  | 
|_________|___________________________________________________________________|
|_____________________________________________________________________________|
*/
Static Function MntStrut(oObj,cAlias, aCampos)
	Local nX
	Default aCampos:={}

	For nX:=1 to Len(aCampos)
		oObj:AddField(;
			aCampos[nX,1],;                                                                              // [01]  C   Titulo do campo
		aCampos[nX,1],;                                                                                  // [02]  C   ToolTip do campo
		aCampos[nX,2],;                                                                                  // [03]  C   Id do Field
		aCampos[nX,3],;                                                                                  // [04]  C   Tipo do campo
		aCampos[nX,4],;                                                                                  // [05]  N   Tamanho do campo
		aCampos[nX,5],;                                                                                  // [06]  N   Decimal do campo
		Nil,;                                                                                            // [07]  B   Code-block de validação do campo
		Nil,;                                                                                            // [08]  B   Code-block de validação When do campo
		{},;                                                                                             // [09]  A   Lista de valores permitido do campo
		.F.,;                                                                                            // [10]  L   Indica se o campo tem preenchimento obrigatório
		FwBuildFeature( STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,('"+cAlias+"')->"+aCampos[nX,2]+",'')" ),;   // [11]  B   Code-block de inicializacao do campo
		.T.,;                                                                                            // [12]  L   Indica se trata-se de um campo chave
		aCampos[nX,6],;                                                                                  // [13]  L   Indica se o campo pode receber valor em uma operação de update.
		.F.)                                                                                             // [14]  L   Indica se o campo é virtual


		IF aCampos[nX,6]
			oObj:SetProperty(aCampos[nX,2], MODEL_FIELD_WHEN, { || .T.})
			oObj:SetProperty(aCampos[nX,2], MODEL_FIELD_NOUPD,.F.)
		EndIF
	Next
Return


/*
______________________________________________________________________________
|_____________________________________________________________________________|
|Programa  - MntView   Autor  Fabricio Antunes      Data   21/09/2021   	  |
|_____________________________________________________________________________|
|Descricao|Funcao auxliar para montagem da estrutura dos campos no Viewdef    |
|         |                                                                   |
|_________|___________________________________________________________________|
|Uso      |                                                                  | 
|_________|___________________________________________________________________|
|_____________________________________________________________________________|
*/
Static Function MntView(oObj,aCampos)
	Local nX


	For nX:=1 to Len(aCampos)
		//Adicionando campos da estrutura
		oObj:AddField(;
			aCampos[nX,1],;                  // [01]  C   Nome do Campo
		aCampos[nX,2],;                  // [02]  C   Ordem
		aCampos[nX,3],;                  // [03]  C   Titulo do campo
		aCampos[nX,3],;                  // [04]  C   Descricao do campo
		Nil,;                            // [05]  A   Array com Help
		aCampos[nX,4],;                  // [06]  C   Tipo do campo
		aCampos[nX,5],;                  // [07]  C   Picture
		Nil,;                            // [08]  B   Bloco de PictTre Var
		Nil,;                            // [09]  C   Consulta F3
		aCampos[nX,6],;                  // [10]  L   Indica se o campo é alteravel
		Nil,;                            // [11]  C   Pasta do campo
		Nil,;                            // [12]  C   Agrupamento do campo
		Nil,;                            // [13]  A   Lista de valores permitido do campo (Combo)
		Nil,;                            // [14]  N   Tamanho maximo da maior opção do combo
		Nil,;                            // [15]  C   Inicializador de Browse
		Nil,;                            // [16]  L   Indica se o campo é virtual
		Nil,;                            // [17]  C   Picture Variavel
		Nil)                             // [18]  L   Indica pulo de linha após o campo
	Next

Return


/*
______________________________________________________________________________
|_____________________________________________________________________________|
|Programa  - movfin     Autor  Fabricio Antunes      Data   21/09/2021   	  |
|_____________________________________________________________________________|
|Descricao|Funcao para calculo do saldo anterior e primeiro registro          |
|         |que atenda a impressão (data emissão >= mv_par01)                  |
|_________|___________________________________________________________________|
|Uso      |                                                                  | 
|_________|___________________________________________________________________|
|_____________________________________________________________________________|
*/

Static function GrvFin(cContab)

	Local	aTam:=TamSX3("E1_CLIENTE")
	Local aCampos := {}
	Local _oFINR5501
	Private cSE5KeyAnt	:= ""

	cOldArea:=Getarea()

	aAdd(aCampos,{"CODIGO" ,"C",aTam[1],aTam[2]})
	aAdd(aCampos,{"SALDOA"  ,"N",18,2})
	aAdd(aCampos,{"VALORD"  ,"N",18,2})
	aAdd(aCampos,{"VALORC"  ,"N",18,2})

	_oFINR5501 := FWTemporaryTable():New( "cNomeArq" )
	_oFINR5501:SetFields(aCampos)
	_oFINR5501:AddIndex("1", {"CODIGO"})
	//------------------
	//Criação da tabela temporaria
	//------------------
	_oFINR5501:Create()

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Localiza e grava titulos a receber dentro dos parametros     ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	cQuery := "SELECT TOP 100 * FROM " + RetSqlName("SE2") + " E2 (NOLOCK) WHERE"
	cQuery += " E2.D_E_L_E_T_ <> '*'"

	dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), 'TRBSE2', .F., .T.)
	dbselectarea("TRBSE2")
	While !TRBSE2->(Eof())

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Le registros com data anterior a data inicial (para compor   ³
		//³ os saldos anteriores) ate a data final.                      ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

		If TRBSE2->E2_TIPO $ MVABATIM
			dbSelectArea("TRBSE2")
			TRBSE2->(dbSkip( ))
			Loop
		Endif


		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Grava debito no arquivo de trabalho                          ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		_dEmissao := stod(TRBSE2->E2_EMIS1)
		aMOVI := {10,20,30}

		If( cNomeArq->(dbseek(TRBSE2->E2_FORNECE)))
			Reclock( "cNomeArq", .F. )
			cNomeArq->SALDOA   += aMOVI[1]
			cNomeArq->VALORD   += aMOVI[2]
			cNomeArq->VALORC   += aMOVI[3]
			cNomeArq->( MsUnlock() )

		Else
			Reclock( "cNomeArq", .T. )
			cNomeArq->CODIGO  := TRBSE2->E2_FORNECE
			cNomeArq->SALDOA   := aMOVI[1]
			cNomeArq->VALORD   := aMOVI[2]
			cNomeArq->VALORC   := aMOVI[3]
			cNomeArq->( MsUnlock() )
		Endif


		dbSelectArea("TRBSE2")
		TRBSE2->(dbSkip())

	Enddo

	dbselectarea("cNomeArq")
	cNomeArq->(dbgotop())
	cCodigo		:= ""
	nSaldoAtu	:= 0
	nTotDeb		:= 0
	nTotCrd		:= 0

	While cNomeArq->(!Eof())

		cCodigo		:= cNomeArq->CODIGO
		cLoja := ""
		nSaldoAtu	:= 0
		nTotDeb		:= 0
		nTotCrd		:= 0
		lNoSkip := .f.
		nSaldoAtu	+= cNomeArq->SALDOA
		nTotDeb   += ABS(cNomeArq->VALORD)
		nTotCrd   += ABS(cNomeArq->VALORC)

		cNomeArq->(dbSkip())
		//cAlisCab:=oGrd1:GetRealName()

		If cNomeArq->(Eof()) .or. cNomeArq->CODIGO <> cCodigo
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Grava debito no arquivo de trabalho                          ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			dbSelectArea(cAlisCab)
			(cAlisCab)->(dbSetOrder(2))
			Reclock((cAlisCab),.t.)
			Replace ID  	    With cCodigo
			Replace ITEM_TAB  	With cCodigo
			IF SA1->(dbseek(xfilial("SA1")+cCodigo))
				Replace DESC_ITEM  	With SA1->A1_NOME
			ElseIf SA2->(dbseek(xfilial("SA2")+cCodigo))
				Replace DESC_ITEM  	With SA2->A2_NOME
			Endif
			Replace FIN_SLA  With nSaldoAtu
			Replace FIN_DEB  With nTotDeb
			Replace FIN_CRE  With nTotCrd
			Replace FIN_SLF  With FIN_SLA + FIN_DEB - FIN_CRE
			MsUnlock()

////grid 1
			dbSelectArea(cAlisGr1)
			(cAlisGr1)->(dbSetOrder(2))
			Reclock((cAlisGr1),.t.)
			Replace ID  	    With cCodigo
			Replace ITEM  	With cCodigo
			Replace FIN_DEB  With nTotDeb
			MsUnlock()
///grid 2

			// dbSelectArea(cAlisGr2)
			// (cAlisGr2)->(dbSetOrder(2))
			// Reclock((cAlisGr2),.t.)
			// Replace ID  	    With cCodigo
			// Replace ITEM 	With cCodigo
			// Replace FIN_DEB  With nTotDeb
			// MsUnlock()
		Endif
	EndDo
	RestArea(cOldArea)
Return


/*
______________________________________________________________________________
|_____________________________________________________________________________|
|Programa  - MCON01A   Autor  Fabricio Antunes      Data   22/11/2020    	  |
|_____________________________________________________________________________|
|Descricao|Funcao para alimentar campos de resultados                         |
|         |                                                                   |
|_________|___________________________________________________________________|
|Uso      |                                                                  | 
|_________|___________________________________________________________________|
|_____________________________________________________________________________|
*/


User Function MCON01A

Private oReport
Private oSecCabc
Private oSecFinan
Private oSecCont


oReport := ReportDef()
oReport:PrintDialog()


Return

/*
______________________________________________________________________________
|_____________________________________________________________________________|
|Programa  - ReportDef   Autor  Fabricio Antunes      Data   08/02/2021       |
|_____________________________________________________________________________|
|Descricao|Montagem de relatorio T-Report                                     |
|         |                                                                   |
|_________|___________________________________________________________________|
|Uso      |                                                                  | 
|_________|___________________________________________________________________|
|_____________________________________________________________________________|
*/
Static Function ReportDef()


oReport := TReport():New("MCON001","Conciliacao Financeiro Contabil",,{|oReport| PrintReport(oReport)},"Conciliacao Financeiro Contabil")
oReport:SetLandscape(.T.) //Paisagem
//oReport:SetPortrait(.T.) //Retrato
oReport:lDisableOrientation := .T.
oReport:HideParamPage()//desabilita a impressão da pagina de parâmetros  

//oReport:nFontBody:=9


oSecCabc := TRSection():New(oReport,"SINTETICO",)
TRCell():New( oSecCabc ,"ITEM_TAB"			,"" ,"Codigo" 			,"@!"/*Picture*/				,   /*nSize*/,/*lPixel*/,/*bBlock*/,"LEFT"/*cAlign*/,/*lLineBreak*/,"LEFT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,.T./*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New( oSecCabc ,"DESC_ITEM"			,"" ,"Nome"				,"@!"/*Picture*/				,   /*nSize*/,/*lPixel*/,/*bBlock*/,"LEFT"/*cAlign*/,/*lLineBreak*/,"LEFT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,.T./*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New( oSecCabc ,"FIN_SLA"			,"" ,"Fin. Sl. Ant."	,"@E 99,999,999.99"/*Picture*/	,   /*nSize*/,/*lPixel*/,/*bBlock*/,"LEFT"/*cAlign*/,/*lLineBreak*/,"LEFT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,.T./*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New( oSecCabc ,"FIN_DEB"			,"" ,"Fin. Debito"		,"@E 99,999,999.99"/*Picture*/	,   /*nSize*/,/*lPixel*/,/*bBlock*/,"LEFT"/*cAlign*/,/*lLineBreak*/,"LEFT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,.T./*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New( oSecCabc ,"FIN_CRE"			,"" ,"Fin. Credito"		,"@E 99,999,999.99"/*Picture*/	,   /*nSize*/,/*lPixel*/,/*bBlock*/,"LEFT"/*cAlign*/,/*lLineBreak*/,"LEFT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,.T./*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New( oSecCabc ,"FIN_SLF"			,"" ,"Fin. Sl. Fin."	,"@E 99,999,999.99"/*Picture*/	,   /*nSize*/,/*lPixel*/,/*bBlock*/,"LEFT"/*cAlign*/,/*lLineBreak*/,"LEFT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,.T./*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New( oSecCabc ,"CTB_SLA"			,"" ,"Ctb. Sl. Ant."	,"@E 99,999,999.99"/*Picture*/	,   /*nSize*/,/*lPixel*/,/*bBlock*/,"LEFT"/*cAlign*/,/*lLineBreak*/,"LEFT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,.T./*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New( oSecCabc ,"CTB_DEB"			,"" ,"Ctb. Debito"		,"@E 99,999,999.99"/*Picture*/	,   /*nSize*/,/*lPixel*/,/*bBlock*/,"LEFT"/*cAlign*/,/*lLineBreak*/,"LEFT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,.T./*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New( oSecCabc ,"CTB_CRE"			,"" ,"Ctb. Credito"		,"@E 99,999,999.99"/*Picture*/	,   /*nSize*/,/*lPixel*/,/*bBlock*/,"LEFT"/*cAlign*/,/*lLineBreak*/,"LEFT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,.T./*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New( oSecCabc ,"CTB_SLF"			,"" ,"Ctb. Sl. Fin."	,"@E 99,999,999.99"/*Picture*/	,   /*nSize*/,/*lPixel*/,/*bBlock*/,"LEFT"/*cAlign*/,/*lLineBreak*/,"LEFT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,.T./*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New( oSecCabc ,"DEF_TAB"			,"" ,"Div."				,"@!"/*Picture*/				,   /*nSize*/,/*lPixel*/,/*bBlock*/,"LEFT"/*cAlign*/,/*lLineBreak*/,"LEFT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,.T./*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New( oSecCabc ,"DIF_VAL"			,"" ,"Diferença"		,"@E 99,999,999.99"/*Picture*/	,   /*nSize*/,/*lPixel*/,/*bBlock*/,"LEFT"/*cAlign*/,/*lLineBreak*/,"LEFT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,.T./*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)


oSecFinan := TRSection():New(oReport,"FINANCEIRO","TRB")

TRCell():New(oSecFinan	,"DATS"			,"" ,"Data"	        ,X3Picture("E1_EMISSAO"),   /*nSize*/,/*lPixel*/,/*bBlock*/,"LEFT"/*cAlign*/,/*lLineBreak*/,"LEFT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,.T./*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSecFinan	,"DOC"			,"" ,"Documento"	,X3Picture("E1_MUM")	,   /*nSize*/,/*lPixel*/,/*bBlock*/,"LEFT"/*cAlign*/,/*lLineBreak*/,"LEFT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,.T./*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSecFinan	,"HIST"			,"" ,"Historico"	,X3Picture("E1_HIST")	,   /*nSize*/,/*lPixel*/,/*bBlock*/,"LEFT"/*cAlign*/,/*lLineBreak*/,"LEFT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,.T./*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSecFinan	,"FIN_DEB"		,"" ,"Fin. Debit."	,X3Picture("E1_VALOR")	,   /*nSize*/,/*lPixel*/,/*bBlock*/,"LEFT"/*cAlign*/,/*lLineBreak*/,"LEFT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,.T./*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSecFinan	,"FIN_CRED"		,"" ,"Fin. Cred."	,X3Picture("E1_VALOR")	,   /*nSize*/,/*lPixel*/,/*bBlock*/,"LEFT"/*cAlign*/,/*lLineBreak*/,"LEFT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,.T./*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSecFinan	,"SALDO"		,"" ,"Saldo"	    ,X3Picture("E1_VALOR")	,   /*nSize*/,/*lPixel*/,/*bBlock*/,"LEFT"/*cAlign*/,/*lLineBreak*/,"LEFT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,.T./*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)

oSecFinan:SetLinesBefore(2)


oSecCont := TRSection():New(oReport,"CONTABIL","TRB")

TRCell():New(oSecCont	,"DATS"			,"" ,"Data"	        ,X3Picture("E1_EMISSAO"),   /*nSize*/,/*lPixel*/,/*bBlock*/,"LEFT"/*cAlign*/,/*lLineBreak*/,"LEFT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,.T./*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSecCont	,"LOTE"			,"" ,"Lote"			,X3Picture("E1_MUM")	,   /*nSize*/,/*lPixel*/,/*bBlock*/,"LEFT"/*cAlign*/,/*lLineBreak*/,"LEFT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,.T./*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSecCont	,"HIST"			,"" ,"Historico"	,X3Picture("E1_HIST")	,   /*nSize*/,/*lPixel*/,/*bBlock*/,"LEFT"/*cAlign*/,/*lLineBreak*/,"LEFT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,.T./*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSecCont	,"FIN_DEB"		,"" ,"Fin. Debit."	,X3Picture("E1_VALOR")	,   /*nSize*/,/*lPixel*/,/*bBlock*/,"LEFT"/*cAlign*/,/*lLineBreak*/,"LEFT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,.T./*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSecCont	,"FIN_CRED"		,"" ,"Fin. Cred."	,X3Picture("E1_VALOR")	,   /*nSize*/,/*lPixel*/,/*bBlock*/,"LEFT"/*cAlign*/,/*lLineBreak*/,"LEFT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,.T./*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSecCont	,"SALDO"		,"" ,"Saldo"	    ,X3Picture("E1_VALOR")	,   /*nSize*/,/*lPixel*/,/*bBlock*/,"LEFT"/*cAlign*/,/*lLineBreak*/,"LEFT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,.T./*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)

oSecCont:SetLinesBefore(2)



Return(oReport)
/*
______________________________________________________________________________
|_____________________________________________________________________________|
|Programa  - PrintReport   Autor  Fabricio Antunes      Data   08/02/2021     |
|_____________________________________________________________________________|
|Descricao|Funcao responsavel pela impressao do relatório                     |
|         |                                                                   |
|_________|___________________________________________________________________|
|Uso      |                                                                  | 
|_________|___________________________________________________________________|
|_____________________________________________________________________________|
*/
Static Function PrintReport(oReport)


oSecCabc:Init()

oSecCabc:Cell("ITEM_TAB"):SetValue((cAlisCab)->ITEM_TAB)
oSecCabc:Cell("DESC_ITEM"):SetValue((cAlisCab)->DESC_ITEM)
oSecCabc:Cell("FIN_SLA"):SetValue((cAlisCab)->FIN_SLA)
oSecCabc:Cell("FIN_DEB"):SetValue((cAlisCab)->FIN_DEB)
oSecCabc:Cell("FIN_CRE"):SetValue((cAlisCab)->FIN_CRE)
oSecCabc:Cell("FIN_SLF"):SetValue((cAlisCab)->FIN_SLF)
oSecCabc:Cell("CTB_SLA"):SetValue((cAlisCab)->CTB_SLA)
oSecCabc:Cell("CTB_DEB"):SetValue((cAlisCab)->CTB_DEB)
oSecCabc:Cell("CTB_CRE"):SetValue((cAlisCab)->CTB_CRE)
oSecCabc:Cell("CTB_SLF"):SetValue((cAlisCab)->CTB_SLF)
oSecCabc:Cell("DEF_TAB"):SetValue((cAlisCab)->DEF_TAB)
oSecCabc:Cell("DIF_VAL"):SetValue((cAlisCab)->DIF_VAL)

oSecCabc:PrintLine()
oSecCabc:Finish()


oReport:Say(oReport:Row()+20, 10, " --------------------DADOS FINANCEIROS--------------------")
oSecFinan:Init()
(cAlisGr1)->(dbSetOrder(1))
(cAlisGr1)->(dbGoTop())
IF (cAlisGr1)->(dbSeek((cAlisCab)->ID))
	While !(cAlisGr1)->(Eof()) .AND. (cAlisGr1)->ID = (cAlisCab)->ID

		If oReport:Cancel()
			Exit
		EndIf

		oSecFinan:Cell("DATS"):SetValue((cAlisGr1)->DATS)
		oSecFinan:Cell("DOC"):SetValue((cAlisGr1)->DOC)
		oSecFinan:Cell("HIST"):SetValue((cAlisGr1)->HIST)
		oSecFinan:Cell("FIN_DEB"):SetValue((cAlisGr1)->FIN_DEB)
		oSecFinan:Cell("FIN_CRED"):SetValue((cAlisGr1)->FIN_CRED)
		oSecFinan:Cell("SALDO"):SetValue((cAlisGr1)->SALDO)

		
		oSecFinan:PrintLine()
		(cAlisGr1)->(dbSkip())
	EndDo
EndIF
oSecFinan:Finish()


oReport:Say(oReport:Row()+20, 10, " --------------------DADOS CONTABILIDADE--------------------")

oSecCont:Init()
(cAlisGr2)->(dbSetOrder(1))
(cAlisGr2)->(dbGoTop())
IF (cAlisGr2)->(dbSeek((cAlisCab)->ID))
	While !(cAlisGr2)->(Eof()) .AND. (cAlisGr2)->ID = (cAlisCab)->ID

		If oReport:Cancel()
			Exit
		EndIf

		oSecCont:Cell("DATS"):SetValue((cAlisGr2)->DATS)
		oSecCont:Cell("LOTE"):SetValue((cAlisGr2)->LOTE)
		oSecCont:Cell("HIST"):SetValue((cAlisGr2)->HIST)
		oSecCont:Cell("FIN_DEB"):SetValue((cAlisGr2)->FIN_DEB)
		oSecCont:Cell("FIN_CRED"):SetValue((cAlisGr2)->FIN_CRED)
		oSecCont:Cell("SALDO"):SetValue((cAlisGr2)->SALDO)

		
		oSecCont:PrintLine()
		(cAlisGr2)->(dbSkip())
	EndDo
EndIf
oSecCont:Finish()

oReport:StartPage()
oReport:EndPage()

Return



/*
______________________________________________________________________________
|_____________________________________________________________________________|
|Programa  - loadGrd   Autor  Fabricio Antunes      Data   08/02/2021     |
|_____________________________________________________________________________|
|Descricao|Função responsável pela carga dos submodelos do MVC.               | 
|         |@param	oSub, objeto, instância da classe FWFormFieldsModel ou da |
|         |classe FWFormGridModel                                             |
|         |cIdSub, caractere, id do submodelo que será carregado             |
|         |                                                                   |
|_________|___________________________________________________________________|
|Uso      |                                                                  | 
|_________|___________________________________________________________________|
|_____________________________________________________________________________|
*/

Static Function loadGrd(oSub,lCopy,cIdSub)

Local cAliasTab	:= ""

Local nI		:= 0
Local nRec		:=1
Local aFldSub	:= {}
Local aRet 		:= {}
Local aAux		:= {}



aFldSub := oSub:GetStruct():GetFields()

If ( cIdSub == "GR1" ) 
	cAliasTab := oGrd1:GetAlias()
ElseIf ( cIdSub == "GR2" )
	cAliasTab := oGrd2:GetAlias()
EndIf		



(cAliasTab)->(DbGoTop())

(cAliasTab)->(dbSetOrder(1))
(cAliasTab)->(dbGoTop())
IF (cAliasTab)->(dbSeek((cAlisCab)->ID))
	While !(cAliasTab)->(Eof()) .AND. (cAliasTab)->ID = (cAlisCab)->ID
				
		For nI := 1 to Len(aFldSub)

			If ( (cAliasTab)->(FieldPos(aFldSub[nI,3])) > 0 )
				aAdd(aAux,(cAliasTab)->&(aFldSub[nI,3]))
			Else
				aAdd(aAux,GTPCastType(,aFldSub[nI,4]))
			EndIf

		Next nI
		
		aAdd(aRet,{nRec,aClone(aAux)})
		aAux := {}
		nRec++
		
		(cAliasTab)->(DbSkip())
		
	EndDo
EndIF



Return(aRet)
