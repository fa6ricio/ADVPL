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
|Uso      |                                                                   | 
|_________|___________________________________________________________________|
|_____________________________________________________________________________|
*/
User Function MFAT001()
Local lLoop:=.T.

While lLoop
    U_MFAT01A()
    IF !MsgYesNo("Deseja precificar outra nota?")
        lLoop:=.F.
    EndIF
EndDo

Return

User Function MFAT01A()

    Local aCampos    := {}
    Local cArqTrb
    Local cIndice1, cIndice2, cIndice3:= ""
    Local lMarcar      := .F.
    Local aSeek   := {}
	Local aPergs   := {}
	Local dDataDe  := sTod('20200101')
	Local dDataAt  := sTod('20291231')
    Local cNota
    Local cSerie
    Local cFornece
    Local cLoja
    Local cQuery:=""
    Local nTipo:=2
	Private cAliasT := "TRB"
	Private oBrowse := Nil	
    Private nVias   :=1
    Private cCadastro     := "Precificao          "
    Private aRotina         := Menudef() //Se for criar menus via MenuDef
    Private cAliasTRB:="TRB"
    
    aAdd(aPergs,{3,"Opcao de Filtro",1,{"Nota Fiscal","Produto","Desmontagem"},50,"",.T.}) 

    IF ParamBox(aPergs, "Escolha opcao de filtro")

        nTipo:= MV_PAR01
        aPergs:={}

        IF nTipo = 1
            // pergunta data ao abrir a tela
            aAdd(aPergs, {1, "Data De",  dDataDe,  "", ".T.", "", ".T.", 80,  .F.})
            aAdd(aPergs, {1, "Data Ate", dDataAt,  "", ".T.", "", ".T.", 80,  .T.})
            aAdd(aPergs, {1, "Nota Fiscal", Space(9),  "@!", ".T.", "SF1X", ".T.", 9,  .F.})
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

            cQuery +=  " SELECT '   ' AS TRB_MARK,LTRIM(RTRIM(B1_GRUPO)) AS B1_GRUPO, LTRIM(RTRIM(BM_DESC)) AS BM_DESC, LTRIM(RTRIM(B1_COD)) AS B1_COD, LTRIM(RTRIM(B1_DESC)) AS B1_DESC, LTRIM(RTRIM(B1_CODBAR)) AS B1_CODBAR, SD1.D1_EMISSAO, (SD1.D1_CUSTO/SD1.D1_QUANT) AS D1_VUNIT , DA1.DA1_PRCVEN, SB1.B1_MARKUP, SB1.B1_PICM, 0 as B2_SALDAT "
            cQuery += " ,((SD1.D1_VUNIT-SD1.D1_VALDESC/SD1.D1_QUANT )/((SB1.B1_MARKUP+SB1.B1_PICM-100)/100))*-1 PRCSUG" // preço sugerido
            cQuery += " ,((SD1.D1_VUNIT-SD1.D1_VALDESC/SD1.D1_QUANT )/((SB1.B1_MARKUP+SB1.B1_PICM-100)/100))*-1-DA1.DA1_PRCVEN DIFVALOR"  //diferença em valor 12-10 = 2
            cQuery += " ,0 DIFPERC  "	// diferença em percentual 12/10*100-100=20
            cQuery += " ,SD1.R_E_C_N_O_ D1_RECNO, DA1.R_E_C_N_O_ DA1_RECNO, SD1.D1_FORNECE, SD1.D1_LOJA, '  ' AS A2_NREDUZ, SD1.D1_DOC, 0 AS D1_VALDESC, SD1.D1_QUANT, 0 AS B2_QATU "
            cQuery +=  " FROM SD1010 SD1"
            cQuery +=  " INNER JOIN SB1010 SB1 ON B1_COD = D1_COD "
            cQuery +=  " LEFT OUTER JOIN DA1010 DA1 ON D1_COD = DA1_CODPRO AND DA1.DA1_CODTAB = '"+GetMV("MV_TABPAD")+"' AND DA1.DA1_FILIAL = '" + xFilial("DA1") + "' AND DA1.D_E_L_E_T_ = ''"
            cQuery +=  " LEFT OUTER JOIN SBM010 SBM ON B1_GRUPO = BM_GRUPO AND SBM.BM_FILIAL = '" + xFilial("SBM") + "'"
            cQuery +=  " WHERE"
            cQuery +=  " SB1.D_E_L_E_T_ = ''"
            cQuery +=  " AND SD1.D_E_L_E_T_ = ''"
            cQuery +=  " AND SD1.D1_TIPO <> 'C'
            cQuery +=  " AND SB1.B1_FILIAL = '" + xFilial("SB1") + "'"
            cQuery +=  " AND SD1.D1_FILIAL = '" + xFilial("SD1") + "'"

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

            cQuery += " ORDER BY D1_DOC, D1_SERIE, D1_ITEM "
        ElseIF nTipo = 2
            aAdd(aPergs, {1, "Produto de", Space(6),  "@!", ".T.", "SB1LIK", ".T.", 6,  .F.})
            aAdd(aPergs, {1, "Produto até", 'ZZZZZZ',  "@!", ".T.", "SB1LIK", ".T.", 6,  .F.})
            aAdd(aPergs, {1, "Codigo de Barras", Space(15),  "@!", ".T.", "", ".T.", 80,  .F.})
            aAdd(aPergs, {1, "Grupo", Space(2),  "@!", ".T.", "MVGR", ".T.", 2,  .F.})
            aAdd(aPergs, {1, "Categoria", Space(2),  "@!", ".T.", "MVCT", ".T.", 2,  .F.})
            aAdd(aPergs, {1, "Sub Categoria", Space(2),  "@!", ".T.", "MVSC", ".T.", 2,  .F.})
            aAdd(aPergs, {1, "Segmento", Space(2),  "@!", ".T.", "MVSG", ".T.", 2,  .F.})
            aAdd(aPergs, {1, "Marca", Space(2),  "@!", ".T.", "MVMR", ".T.", 2,  .F.})


            If ParamBox(aPergs, "Informe os parâmetros")


                cQuery +=  " SELECT TOP 1 '   ' AS TRB_MARK,LTRIM(RTRIM(B1_GRUPO)) AS B1_GRUPO, LTRIM(RTRIM(BM_DESC)) AS BM_DESC, LTRIM(RTRIM(B1_COD)) AS B1_COD, LTRIM(RTRIM(B1_DESC)) AS B1_DESC, LTRIM(RTRIM(B1_CODBAR)) AS B1_CODBAR, SD1.D1_EMISSAO, (SD1.D1_CUSTO/SD1.D1_QUANT) AS D1_VUNIT , DA1.DA1_PRCVEN, SB1.B1_MARKUP, SB1.B1_PICM, 0 as B2_SALDAT "
                cQuery += " ,((SD1.D1_VUNIT-SD1.D1_VALDESC/SD1.D1_QUANT )/((SB1.B1_MARKUP+SB1.B1_PICM-100)/100))*-1 PRCSUG" // preço sugerido
                cQuery += " ,((SD1.D1_VUNIT-SD1.D1_VALDESC/SD1.D1_QUANT )/((SB1.B1_MARKUP+SB1.B1_PICM-100)/100))*-1-DA1.DA1_PRCVEN DIFVALOR"  //diferença em valor 12-10 = 2
                cQuery += " ,0 DIFPERC  "	// diferença em percentual 12/10*100-100=20
                cQuery += " ,SD1.R_E_C_N_O_ D1_RECNO, DA1.R_E_C_N_O_ DA1_RECNO, SD1.D1_FORNECE, SD1.D1_LOJA, '  ' AS A2_NREDUZ, SD1.D1_DOC, 0 AS D1_VALDESC, SD1.D1_QUANT, 0 AS B2_QATU "
                cQuery +=  " FROM SD1010 SD1"
                cQuery +=  " INNER JOIN SB1010 SB1 ON B1_COD = D1_COD "
                cQuery +=  " LEFT OUTER JOIN DA1010 DA1 ON D1_COD = DA1_CODPRO AND DA1.DA1_CODTAB = '"+GetMV("MV_TABPAD")+"' AND DA1.DA1_FILIAL = '" + xFilial("DA1") + "' AND DA1.D_E_L_E_T_ = ''"
                cQuery +=  " LEFT OUTER JOIN SBM010 SBM ON B1_GRUPO = BM_GRUPO AND SBM.BM_FILIAL = '" + xFilial("SBM") + "'"
                cQuery +=  " WHERE"
                cQuery +=  " SB1.D_E_L_E_T_ = ''"
                cQuery +=  " AND SD1.D_E_L_E_T_ = ''"
                cQuery +=  " AND SD1.D1_TIPO <> 'C'
                cQuery +=  " AND SB1.B1_FILIAL = '" + xFilial("SB1") + "'"
                cQuery +=  " AND SD1.D1_FILIAL = '" + xFilial("SD1") + "'"
                cQuery +=  " AND SB1.B1_COD >= '"+MV_PAR01+"' AND SB1.B1_COD <= '"+MV_PAR02+"' "

                IF Alltrim(MV_PAR04) <> '' 
                    cQuery+=" AND B1_XGRUPO = '"+MV_PAR04+"' "
                EndIF

                IF Alltrim(MV_PAR05) <> ''
                    cQuery+=" AND  B1_XCATEGO = '"+MV_PAR05+"' "
                EndIf

                IF Alltrim(MV_PAR06) <> ''
                    cQuery+=" AND  B1_XSUBCAT  = '"+MV_PAR06+"' "
                EndIF

                IF  Alltrim(MV_PAR07) <> ''
                    cQuery+=" AND  B1_XSEGMEN  = '"+MV_PAR07+"' "
                EndIF

                IF  Alltrim(MV_PAR08) <> ''
                    cQuery+=" AND  B1_XMARCA  = '"+MV_PAR08+"' "
                EndIf

                IF  Alltrim(MV_PAR03) <> ''
                    cQuery+=" AND  B1_CODBAR  = '"+MV_PAR03+"' "
		        EndIf
                cQuery+= " ORDER BY D1_EMISSAO DESC "
            EndIF
        ElseIF nTipo = 3
            aAdd(aPergs, {1, "Nota Fiscal Carcaca", Space(9),  "@!", ".T.", "SF1X", ".T.", 9,  .F.})
            aAdd(aPergs, {1, "Serie Carcaca", Space(3),  "@!", ".T.", "", ".T.", 3,  .F.})
            aAdd(aPergs, {1, "Fornecedor", Space(6),  "@!", ".T.", "SA1", ".T.", 6,  .F.})
            aAdd(aPergs, {1, "Loja", Space(4),  "@!", ".T.", "", ".T.", 4,  .F.})
            aAdd(aPergs, {1, "Documento Desmontagem", Space(9),  "@!", ".T.", "", ".T.", 9,  .F.})
            aAdd(aPergs, {1, "Numero Vias",1,"@E 999","mv_par06>=1","","",3,.T.}) 

            If ParamBox(aPergs, "Informe os parâmetros")


            cQuery +=  " SELECT '   ' AS TRB_MARK, B1_GRUPO, BM_DESC, B1_COD, B1_DESC, B1_CODBAR, SD3.D3_EMISSAO AS D1_EMISSAO, 0 AS D1_VUNIT , DA1.DA1_PRCVEN, SB1.B1_MARKUP, SB1.B1_PICM, 0 as B2_SALDAT "
            cQuery += " ,0 PRCSUG" 
            cQuery += " ,0 DIFVALOR"
            cQuery += " ,0 DIFPERC  "
            cQuery += " ,SD3.R_E_C_N_O_ D3_RECNO, DA1.R_E_C_N_O_ DA1_RECNO, '' AS D1_FORNECE, '' AS D1_LOJA, '  ' AS A2_NREDUZ, '' AS D1_DOC, 0 AS D1_VALDESC, SD3.D3_QUANT AS D1_QUANT, 0 AS B2_QATU , D3_RATEIO"
            cQuery +=  " FROM SD3010 SD3"
            cQuery +=  " INNER JOIN SB1010 SB1 ON B1_COD = D3_COD "
            cQuery +=  " LEFT OUTER JOIN DA1010 DA1 ON D3_COD = DA1_CODPRO AND DA1.DA1_CODTAB = '"+GetMV("MV_TABPAD")+"' AND DA1.DA1_FILIAL = '" + xFilial("DA1") + "' AND DA1.D_E_L_E_T_ = ''"
            cQuery +=  " LEFT OUTER JOIN SBM010 SBM ON B1_GRUPO = BM_GRUPO AND SBM.BM_FILIAL = '" + xFilial("SBM") + "'"
            cQuery +=  " WHERE"
            cQuery +=  " SB1.D_E_L_E_T_ = ''"
            cQuery +=  " AND SD3.D_E_L_E_T_ = ''"
            cQuery +=  " AND SD3.D3_CF = 'DE7'
            cQuery +=  " AND SB1.B1_FILIAL = '" + xFilial("SB1") + "'"
            cQuery +=  " AND SD3.D3_DOC = '"+MV_PAR05+"'"
            cQuery+= " ORDER BY D3_COD "
        EndIF

    EndIF
        //Criar a tabela temporária
        AAdd(aCampos,{"TRB_MARK","C",3,0})
        AAdd(aCampos,{"B1_GRUPO"     ,TamSX3('B1_GRUPO')[3]     ,TamSX3('B1_GRUPO')[1]  ,TamSX3('B1_GRUPO')[2]})
        AAdd(aCampos,{"BM_DESC"      ,TamSX3('BM_DESC')[3]      ,TamSX3('BM_DESC')[1]   ,TamSX3('BM_DESC')[2]})
        AAdd(aCampos,{"B1_COD"       ,TamSX3('B1_COD')[3]       ,TamSX3('B1_COD')[1]    ,TamSX3('B1_COD')[2]})
        AAdd(aCampos,{"B1_DESC"      ,TamSX3('B1_DESC')[3]      ,TamSX3('B1_DESC')[1]-20,TamSX3('B1_DESC')[2]})
        AAdd(aCampos,{"B1_CODBAR"    ,TamSX3('B1_CODBAR')[3]    ,TamSX3('B1_CODBAR')[1] ,TamSX3('B1_CODBAR')[2]})
        AAdd(aCampos,{"D1_EMISSAO"   ,TamSX3('D1_EMISSAO')[3]   ,TamSX3('D1_EMISSAO')[1],TamSX3('D1_EMISSAO')[2]})
        AAdd(aCampos,{"D1_VUNIT"     ,TamSX3('D1_TOTAL')[3]     ,TamSX3('D1_TOTAL')[1]  ,TamSX3('D1_TOTAL')[2]})
        AAdd(aCampos,{"DA1_PRCVEN"   ,TamSX3('D1_TOTAL')[3]     ,TamSX3('D1_TOTAL')[1]  ,TamSX3('D1_TOTAL')[2]})
        AAdd(aCampos,{"B1_MARKUP"    ,TamSX3('B1_MARKUP')[3]    ,TamSX3('B1_MARKUP')[1] ,TamSX3('B1_MARKUP')[2]})
        AAdd(aCampos,{"B1_PICM"      ,TamSX3('B1_PICM')[3]      ,TamSX3('B1_PICM')[1]   ,TamSX3('B1_PICM')[2]})
        AAdd(aCampos,{"PRCSUG"       ,TamSX3('D1_TOTAL')[3]     ,TamSX3('D1_TOTAL')[1]  ,TamSX3('D1_TOTAL')[2]})
        AAdd(aCampos,{"DIFVALOR"     ,TamSX3('D1_TOTAL')[3]     ,TamSX3('D1_TOTAL')[1]  ,TamSX3('D1_TOTAL')[2]})
        AAdd(aCampos,{"DIFPERC"     ,"N",12,2})        
        AAdd(aCampos,{"D1_RECNO"    ,"N",8,0})   
        AAdd(aCampos,{"DA1_RECNO"   ,"N",8,0})   
        AAdd(aCampos,{"D1_FORNECE"  ,TamSX3('D1_FORNECE')[3]   ,TamSX3('D1_FORNECE')[1]  ,TamSX3('D1_FORNECE')[2]})
        AAdd(aCampos,{"D1_LOJA"     ,TamSX3('D1_LOJA')[3]      ,TamSX3('D1_LOJA')[1]     ,TamSX3('D1_LOJA')[2]})
        AAdd(aCampos,{"A2_NREDUZ"   ,TamSX3('A2_NREDUZ')[3]    ,TamSX3('A2_NREDUZ')[1]   ,TamSX3('A2_NREDUZ')[2]})
        AAdd(aCampos,{"D1_DOC"      ,TamSX3('D1_DOC')[3]       ,TamSX3('D1_DOC')[1]      ,TamSX3('D1_DOC')[2]})
        AAdd(aCampos,{"D1_VALDESC"  ,TamSX3('D1_TOTAL')[3]     ,TamSX3('D1_TOTAL')[1]    ,TamSX3('D1_TOTAL')[2]})
        AAdd(aCampos,{"D1_QUANT"    ,TamSX3('D1_QUANT')[3]     ,TamSX3('D1_QUANT')[1]    ,TamSX3('D1_QUANT')[2]})
        AAdd(aCampos,{"B2_SALDAT"   ,TamSX3('B2_QATU')[3]      ,TamSX3('B2_QATU')[1]     ,TamSX3('B2_QATU')[2]})
        AAdd(aCampos,{"B2_QATU"     ,TamSX3('B2_QATU')[3]      ,TamSX3('B2_QATU')[1]     ,TamSX3('B2_QATU')[2]})
        AAdd(aCampos,{"D3_RATEIO"   ,TamSX3('D3_RATEIO')[3]    ,TamSX3('D3_RATEIO')[1]   ,TamSX3('D3_RATEIO')[2]})
        

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
        

        //Funcao para complementar dados quando é desmontagem
        IF nTipo = 3
            lNota:=Desmont()
            IF !lNota
                MsgStop("Nota fiscal de entrada da carcaca nao encontrada, nao sera possivel efetuar precificacao! Favor verificar parametros!", "Erro")
                Return
            EndIF
        EndIF
        //Funcao para atualizacao de produtos com desmonte
        //AtuProd()
        //Funcao para autaliacao da regra de ICMS 
        AtuICM()


        TRB->(DbGoTop())
        
        If TRB->(!Eof())
            //Irei criar a pesquisa que será apresentada na tela
            aAdd(aSeek,{"Descricao"             ,{{"",TamSX3('B1_DESC')[3],TamSX3('B1_DESC')[1]-20,TamSX3('B1_DESC')[2],"Descricao"    ,"@!"}} } )
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
            oBrowse:SetColumns(MCFG006TIT("B1_GRUPO"      ,"Grupo"           ,01,X3Picture("B1_GRUPO")      ,1,TamSX3('B1_GRUPO')[1]    ,TamSX3('B1_GRUPO')[2]))
            oBrowse:SetColumns(MCFG006TIT("BM_DESC"       ,"Desc Grupo"      ,02,X3Picture("BM_DESC")       ,1,TamSX3('BM_DESC')[1]     ,TamSX3('BM_DESC')[2]))
            oBrowse:SetColumns(MCFG006TIT("B1_COD"        ,"Codigo"          ,03,X3Picture("B1_COD")        ,1,TamSX3('B1_COD')[1]      ,TamSX3('B1_COD')[2]))
            oBrowse:SetColumns(MCFG006TIT("B1_DESC"       ,"Descricao"       ,04,X3Picture("B1_DESC")       ,1,TamSX3('B1_DESC')[1]-20     ,TamSX3('B1_DESC')[2]))
            oBrowse:SetColumns(MCFG006TIT("B1_CODBAR"     ,"Cod Barras"      ,05,X3Picture("B1_CODBAR")     ,1,TamSX3('B1_CODBAR')[1]   ,TamSX3('B1_CODBAR')[2]))
            oBrowse:SetColumns(MCFG006TIT("D1_EMISSAO"    ,"Emissao"         ,06,X3Picture("D1_EMISSAO")    ,1,TamSX3('D1_EMISSAO')[1]  ,TamSX3('D1_EMISSAO')[2]))
            oBrowse:SetColumns(MCFG006TIT("B1_PICM"       ,"Aliq ICM"        ,07,X3Picture("B1_PICM")       ,2,TamSX3('B1_PICM')[1]     ,TamSX3('B1_PICM')[2]))
            oBrowse:SetColumns(MCFG006TIT("B1_MARKUP"     ,"Markup"          ,08,X3Picture("D1_TOTAL")      ,2,TamSX3('D1_TOTAL')[1]    ,TamSX3('D1_TOTAL')[2]))
            oBrowse:SetColumns(MCFG006TIT("D1_VUNIT"      ,"Preco Compra"    ,09,X3Picture("D1_TOTAL")      ,1,TamSX3('D1_TOTAL')[1]    ,TamSX3('D1_TOTAL')[2]))    
            oBrowse:SetColumns(MCFG006TIT("DA1_PRCVEN"    ,"Preco Atual"     ,10,X3Picture("D1_TOTAL")      ,2,TamSX3('D1_TOTAL')[1]    ,TamSX3('D1_TOTAL')[2]))
            oBrowse:SetColumns(MCFG006TIT("PRCSUG"        ,"Preco Sugerido"  ,11,X3Picture("D1_TOTAL")      ,2,TamSX3('D1_TOTAL')[1]    ,TamSX3('D1_TOTAL')[2]))
            oBrowse:SetColumns(MCFG006TIT("DIFVALOR"      ,"Dif Valor"       ,12,X3Picture("D1_TOTAL")      ,2,TamSX3('D1_TOTAL')[1]    ,TamSX3('D1_TOTAL')[2]))
            oBrowse:SetColumns(MCFG006TIT("DIFPERC"       ,"Dif Percen"      ,13,X3Picture("D1_TOTAL")      ,0,12  ,2))
            oBrowse:SetColumns(MCFG006TIT("D1_FORNECE"    ,"Fornecedor"      ,14,X3Picture("D1_FORNECE")    ,1,TamSX3('D1_FORNECE')[1]  ,TamSX3('D1_FORNECE')[2]))
            oBrowse:SetColumns(MCFG006TIT("A2_NREDUZ"     ,"Nome"            ,15,X3Picture("A2_NREDUZ")     ,1,TamSX3('A2_NREDUZ')[1]     ,TamSX3('A2_NREDUZ')[2]))
            oBrowse:SetColumns(MCFG006TIT("D1_DOC"        ,"Nota Fiscal"     ,16,X3Picture("D1_DOC")        ,1,TamSX3('D1_DOC')[1]      ,TamSX3('D1_DOC')[2]))
            oBrowse:SetColumns(MCFG006TIT("D1_QUANT"      ,"Qunt Comprada"   ,17,X3Picture("A2_NREDUZ")     ,1,TamSX3('A2_NREDUZ')[1]     ,TamSX3('A2_NREDUZ')[2]))
            oBrowse:SetColumns(MCFG006TIT("B2_SALDAT"     ,"Saldo Anterior"  ,18,X3Picture("B2_QATU")       ,1,TamSX3('B2_QATU')[1]      ,TamSX3('B2_QATU')[2]))
            oBrowse:SetColumns(MCFG006TIT("B2_QATU"       ,"Saldo Atual"     ,19,X3Picture("B2_QATU")       ,1,TamSX3('B2_QATU')[1]      ,TamSX3('B2_QATU')[2]))
            oBrowse:SetColumns(MCFG006TIT("BM_DESC"       ,"Desc Grupo"      ,02,X3Picture("BM_DESC")       ,1,TamSX3('BM_DESC')[1]     ,TamSX3('BM_DESC')[2]))
            oBrowse:SetColumns(MCFG006TIT("B1_COD"        ,"Codigo"          ,03,X3Picture("B1_COD")        ,1,TamSX3('B1_COD')[1]      ,TamSX3('B1_COD')[2]))
            oBrowse:SetColumns(MCFG006TIT("B1_DESC"       ,"Descricao"       ,04,X3Picture("B1_DESC")       ,1,TamSX3('B1_DESC')[1]-20     ,TamSX3('B1_DESC')[2]))
            oBrowse:SetColumns(MCFG006TIT("B1_CODBAR"     ,"Cod Barras"      ,05,X3Picture("B1_CODBAR")     ,1,TamSX3('B1_CODBAR')[1]   ,TamSX3('B1_CODBAR')[2]))
            oBrowse:SetColumns(MCFG006TIT("D1_EMISSAO"    ,"Emissao"         ,06,X3Picture("D1_EMISSAO")    ,1,TamSX3('D1_EMISSAO')[1]  ,TamSX3('D1_EMISSAO')[2]))
            oBrowse:SetColumns(MCFG006TIT("B1_PICM"       ,"Aliq ICM"        ,07,X3Picture("B1_PICM")       ,2,TamSX3('B1_PICM')[1]     ,TamSX3('B1_PICM')[2]))
            oBrowse:SetColumns(MCFG006TIT("B1_MARKUP"     ,"Markup"          ,08,X3Picture("D1_TOTAL")      ,2,TamSX3('D1_TOTAL')[1]    ,TamSX3('D1_TOTAL')[2]))
            oBrowse:SetColumns(MCFG006TIT("D1_VUNIT"      ,"Preco Compra"    ,09,X3Picture("D1_TOTAL")      ,1,TamSX3('D1_TOTAL')[1]    ,TamSX3('D1_TOTAL')[2]))    
            oBrowse:SetColumns(MCFG006TIT("DA1_PRCVEN"    ,"Preco Atual"     ,10,X3Picture("D1_TOTAL")      ,2,TamSX3('D1_TOTAL')[1]    ,TamSX3('D1_TOTAL')[2]))
            oBrowse:SetColumns(MCFG006TIT("PRCSUG"        ,"Preco Sugerido"  ,11,X3Picture("D1_TOTAL")      ,2,TamSX3('D1_TOTAL')[1]    ,TamSX3('D1_TOTAL')[2]))
            oBrowse:SetColumns(MCFG006TIT("DIFVALOR"      ,"Dif Valor"       ,12,X3Picture("D1_TOTAL")      ,2,TamSX3('D1_TOTAL')[1]    ,TamSX3('D1_TOTAL')[2]))
            oBrowse:SetColumns(MCFG006TIT("DIFPERC"       ,"Dif Percen"      ,13,X3Picture("D1_TOTAL")      ,0,12  ,2))
            oBrowse:SetColumns(MCFG006TIT("D1_FORNECE"    ,"Fornecedor"      ,14,X3Picture("D1_FORNECE")    ,1,TamSX3('D1_FORNECE')[1]  ,TamSX3('D1_FORNECE')[2]))
            oBrowse:SetColumns(MCFG006TIT("A2_NREDUZ"     ,"Nome"            ,15,X3Picture("A2_NREDUZ")     ,1,TamSX3('A2_NREDUZ')[1]     ,TamSX3('A2_NREDUZ')[2]))
            oBrowse:SetColumns(MCFG006TIT("D1_DOC"        ,"Nota Fiscal"     ,16,X3Picture("D1_DOC")        ,1,TamSX3('D1_DOC')[1]      ,TamSX3('D1_DOC')[2]))
            oBrowse:SetColumns(MCFG006TIT("D1_QUANT"      ,"Qunt Comprada"   ,17,X3Picture("A2_NREDUZ")     ,1,TamSX3('A2_NREDUZ')[1]     ,TamSX3('A2_NREDUZ')[2]))
            oBrowse:SetColumns(MCFG006TIT("B2_SALDAT"     ,"Saldo Anterior"  ,18,X3Picture("B2_QATU")       ,1,TamSX3('B2_QATU')[1]      ,TamSX3('B2_QATU')[2]))
            oBrowse:SetColumns(MCFG006TIT("B2_QATU"       ,"Saldo Atual"     ,19,X3Picture("B2_QATU")       ,1,TamSX3('B2_QATU')[1]      ,TamSX3('B2_QATU')[2]))
            oBrowse:SetColumns(MCFG006TIT("D3_RATEIO"     ,"Reteio Desmont"  ,20,X3Picture("D3_RATEIO")     ,1,TamSX3('D3_RATEIO')[1]    ,TamSX3('D3_RATEIO')[2]))


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
    EndIF
Return(.T.)


/*
______________________________________________________________________________
|_____________________________________________________________________________|
|Programa  - MCFG6Invert    Autor  Fabricio Antunes      Data   22/11/2020   	  |
|_____________________________________________________________________________|
|Descricao|Controle de Marcacao                                               |
|         |                                                                   |
|_________|___________________________________________________________________|
|Uso      |                                                                   | 
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
|Uso      |                                                                   | 
|_________|___________________________________________________________________|
|_____________________________________________________________________________|
*/
Static Function MenuDef()
    Local aRot := {}
    
    ADD OPTION aRot TITLE "Atualizar Preços" ACTION " MsAguarde({|lEnd| GravaDA1(@lEnd)"   OPERATION 6 ACCESS 0
    ADD OPTION aRot TITLE "Imprimir Etiquetas" ACTION "MsAguarde({|lEnd| ImpEtiq(@lEnd) "  OPERATION 6 ACCESS 0
    ADD OPTION aRot TITLE "Imprimir Relatorio" ACTION "U_ImpRelpr(@lEnd)"    OPERATION 6 ACCESS 0
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
|Uso      |                                                                   | 
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
|Uso      |                                                                   | 
|_________|___________________________________________________________________|
|_____________________________________________________________________________|
*/

Static Function GravaDa1(lEnd)

    Local cQuery
    Local cItem
    Local cTab:=GetMV("MV_TABPAD")

	(cAliasT)->(dbSetOrder(1))
	(cAliasT)->(dbGoTop() )

    cQuery:="SELECT TOP(1) DA1_ITEM FROM "+RetSqlName("DA1")+" WHERE DA1_CODTAB = '"+cTab+"' AND D_E_L_E_T_  = '' ORDER BY R_E_C_N_O_  DESC "
    dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"cSQL",.T.,.T.)
    cItem:=cSQL->DA1_ITEM
    cSQL->(dbCloseArea())
    



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
			Else
                cItem:=Soma1(Alltrim(cItem))
                RecLock("DA1",.T.)
                    DA1->DA1_FILIAL     :=xFilial("DA1")
                    DA1->DA1_CODTAB     :=Alltrim(cTab)
                    DA1->DA1_ITEM       :=cItem
                    DA1->DA1_CODPRO     :=(cAliasT)->B1_COD
                    DA1->DA1_PRCVEN     :=(cAliasT)->PRCSUG
                    DA1->DA1_ATIVO      :="1"
                    DA1->DA1_TPOPER     :="4"
                    DA1->DA1_QTDLOT     :=999999.99
                    DA1->DA1_INDLOT     :="000000000999999.99"
                    DA1->DA1_MOEDA      :=1
                    DA1->DA1_DATVIG     :=Stod("20200101")
                    DA1->DA1_PRCMAX     :=0.00
                    DA1->DA1_MSEXP      :=""
                    DA1->DA1_HREXP      :=""
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
|Uso      |                                                                   | 
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
|Uso      |                                                                   | 
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
        TamSX3('B1_DESC')[1]-20,;                                                                       // [05]  N   Tamanho do campo
        TamSX3('B1_DESC')[2],;                                                                       // [06]  N   Decimal do campo
        Nil,;                                                                                        // [07]  B   Code-block de validação do campo
        Nil,;                                                                                        // [08]  B   Code-block de validação When do campo
        {},;                                                                                         // [09]  A   Lista de valores permitido do campo
        .F.,;                                                                                        // [10]  L   Indica se o campo tem preenchimento obrigatório
        FwBuildFeature( STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTRB+"->B1_DESC,'')" ),;          // [11]  B   Code-block de inicializacao do campo
        .F.,;                                                                                        // [12]  L   Indica se trata-se de um campo chave
        .F.,;                                                                                        // [13]  L   Indica se o campo pode receber valor em uma operação de update.
        .F.)         
                                                                                        // [14]  L   Indica se o campo é virtual
    oStTRB:AddField(;
        "Cod Barras",;                                                                                  // [01]  C   Titulo do campo
        "Cod Barras",;                                                                                  // [02]  C   ToolTip do campo
        "B1_CODBAR",;                                                                                  // [03]  C   Id do Field
        TamSX3('B1_CODBAR')[3],;                                                                       // [04]  C   Tipo do campo
        TamSX3('B1_CODBAR')[1],;                                                                       // [05]  N   Tamanho do campo
        TamSX3('B1_CODBAR')[2],;                                                                       // [06]  N   Decimal do campo
        Nil,;                                                                                       // [07]  B   Code-block de validação do campo
        Nil,;                                                                                       // [08]  B   Code-block de validação When do campo
        {},;                                                                                        // [09]  A   Lista de valores permitido do campo
        .F.,;                                                                                       // [10]  L   Indica se o campo tem preenchimento obrigatório
        FwBuildFeature( STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTRB+"->B1_CODBAR,'')" ),;          // [11]  B   Code-block de inicializacao do campo
        .T.,;                                                                                       // [12]  L   Indica se trata-se de um campo chave
        .F.,;                                                                                       // [13]  L   Indica se o campo pode receber valor em uma operação de update.
        .F.)                                                                                        // [14]  L   Indica se o campo é virtual
  
  
 oStTRB:AddField(;
        "Preco Compra",;                                                                              // [01]  C   Titulo do campo
        "Preco Compra",;                                                                              // [02]  C   ToolTip do campo
        "D1_VUNIT",;                                                                                  // [03]  C   Id do Field
        TamSX3('D1_TOTAL')[3],;                                                                       // [04]  C   Tipo do campo
        TamSX3('D1_TOTAL')[1],;                                                                       // [05]  N   Tamanho do campo
        TamSX3('D1_TOTAL')[2],;                                                                       // [06]  N   Decimal do campo
        Nil,;                                                                                         // [07]  B   Code-block de validação do campo
        Nil,;                                                                                         // [08]  B   Code-block de validação When do campo
        {},;                                                                                          // [09]  A   Lista de valores permitido do campo
        .F.,;                                                                                         // [10]  L   Indica se o campo tem preenchimento obrigatório
        FwBuildFeature( STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTRB+"->D1_VUNIT,'')" ),;          // [11]  B   Code-block de inicializacao do campo
        .F.,;                                                                                         // [12]  L   Indica se trata-se de um campo chave
        .F.,;                                                                                         // [13]  L   Indica se o campo pode receber valor em uma operação de update.
        .F.)                                                                                          // [14]  L   Indica se o campo é virtual
  


 oStTRB:AddField(;
        "Preco Venda",;                                                                               // [01]  C   Titulo do campo
        "Preco Venda",;                                                                               // [02]  C   ToolTip do campo
        "DA1_PRCVEN",;                                                                                // [03]  C   Id do Field
        TamSX3('D1_TOTAL')[3],;                                                                     // [04]  C   Tipo do campo
        TamSX3('D1_TOTAL')[1],;                                                                     // [05]  N   Tamanho do campo
        TamSX3('D1_TOTAL')[2],;                                                                     // [06]  N   Decimal do campo
        Nil,;                                                                                         // [07]  B   Code-block de validação do campo
        Nil,;                                                                                         // [08]  B   Code-block de validação When do campo
        {},;                                                                                          // [09]  A   Lista de valores permitido do campo
        .F.,;                                                                                         // [10]  L   Indica se o campo tem preenchimento obrigatório
        FwBuildFeature( STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTRB+"->DA1_PRCVEN1,'')" ),;       // [11]  B   Code-block de inicializacao do campo
        .F.,;                                                                                         // [12]  L   Indica se trata-se de um campo chave
        .F.,;                                                                                         // [13]  L   Indica se o campo pode receber valor em uma operação de update.
        .F.)                                                                                          // [14]  L   Indica se o campo é virtual
  


 oStTRB:AddField(;
        "Markup",;                                                                                    // [01]  C   Titulo do campo
        "Markup",;                                                                                    // [02]  C   ToolTip do campo
        "B1_MARKUP",;                                                                                 // [03]  C   Id do Field
        TamSX3('D1_TOTAL')[3],;                                                                      // [04]  C   Tipo do campo
        TamSX3('D1_TOTAL')[1],;                                                                      // [05]  N   Tamanho do campo
        TamSX3('D1_TOTAL')[2],;                                                                      // [06]  N   Decimal do campo
        Nil,;                                                                                         // [07]  B   Code-block de validação do campo
        Nil,;                                                                                         // [08]  B   Code-block de validação When do campo
        {},;                                                                                          // [09]  A   Lista de valores permitido do campo
        .F.,;                                                                                         // [10]  L   Indica se o campo tem preenchimento obrigatório
        FwBuildFeature( STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTRB+"->B1_MARKUP,'')" ),;         // [11]  B   Code-block de inicializacao do campo
        .F.,;                                                                                         // [12]  L   Indica se trata-se de um campo chave
        .F.,;                                                                                         // [13]  L   Indica se o campo pode receber valor em uma operação de update.
        .F.)                                                                                          // [14]  L   Indica se o campo é virtual
  

 oStTRB:AddField(;
        "Aliq ICM",;                                                                                   // [01]  C   Titulo do campo
        "Aliq ICM",;                                                                                   // [02]  C   ToolTip do campo
        "B1_PICM",;                                                                                    // [03]  C   Id do Field
        TamSX3('B1_PICM')[3],;                                                                         // [04]  C   Tipo do campo
        TamSX3('B1_PICM')[1],;                                                                         // [05]  N   Tamanho do campo
        TamSX3('B1_PICM')[2],;                                                                         // [06]  N   Decimal do campo
        Nil,;                                                                                          // [07]  B   Code-block de validação do campo
        Nil,;                                                                                          // [08]  B   Code-block de validação When do campo
        {},;                                                                                           // [09]  A   Lista de valores permitido do campo
        .F.,;                                                                                          // [10]  L   Indica se o campo tem preenchimento obrigatório
        FwBuildFeature( STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTRB+"->B1_PICM,'')" ),;            // [11]  B   Code-block de inicializacao do campo
        .F.,;                                                                                          // [12]  L   Indica se trata-se de um campo chave
        .F.,;                                                                                          // [13]  L   Indica se o campo pode receber valor em uma operação de update.
        .F.)                                                                                           // [14]  L   Indica se o campo é virtual


 oStTRB:AddField(;
        "Preco Sugerido",;                                                                              // [01]  C   Titulo do campo
        "Preco Sugerido",;                                                                              // [02]  C   ToolTip do campo
        "PRCSUG",;                                                                                      // [03]  C   Id do Field
        TamSX3('D1_TOTAL')[3],;                                                                       // [04]  C   Tipo do campo
        TamSX3('D1_TOTAL')[1],;                                                                       // [05]  N   Tamanho do campo
        TamSX3('D1_TOTAL')[2],;                                                                       // [06]  N   Decimal do campo
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
        TamSX3('D1_TOTAL')[3],;                                                                       // [04]  C   Tipo do campo
        TamSX3('D1_TOTAL')[1],;                                                                       // [05]  N   Tamanho do campo
        TamSX3('D1_TOTAL')[2],;                                                                       // [06]  N   Decimal do campo
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
        2,;                                                                                         // [06]  N   Decimal do campo
        Nil,;                                                                                       // [07]  B   Code-block de validação do campo
        Nil,;                                                                                       // [08]  B   Code-block de validação When do campo
        {},;                                                                                        // [09]  A   Lista de valores permitido do campo
        .F.,;                                                                                       // [10]  L   Indica se o campo tem preenchimento obrigatório
        FwBuildFeature( STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTRB+"->DIFPERC,'')" ),;         // [11]  B   Code-block de inicializacao do campo
        .F.,;                                                                                       // [12]  L   Indica se trata-se de um campo chave
        .F.,;                                                                                       // [13]  L   Indica se o campo pode receber valor em uma operação de update.
        .F.)                                                                                        // [14]  L   Indica se o campo é virtual
  
 oStTRB:AddField(;
        "Fornecedor",;                                                                              // [01]  C   Titulo do campo
        "Fornecedor",;                                                                              // [02]  C   ToolTip do campo
        "D1_FORNECE",;                                                                              // [03]  C   Id do Field
        TamSX3('D1_FORNECE')[3],;                                                                   // [04]  C   Tipo do campo
        TamSX3('D1_FORNECE')[1],;                                                                   // [05]  N   Tamanho do campo
        TamSX3('D1_FORNECE')[1],;                                                                   // [06]  N   Decimal do campo
        Nil,;                                                                                       // [07]  B   Code-block de validação do campo
        Nil,;                                                                                       // [08]  B   Code-block de validação When do campo
        {},;                                                                                        // [09]  A   Lista de valores permitido do campo
        .F.,;                                                                                       // [10]  L   Indica se o campo tem preenchimento obrigatório
        FwBuildFeature( STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTRB+"->D1_FORNECE,'')" ),;      // [11]  B   Code-block de inicializacao do campo
        .F.,;                                                                                       // [12]  L   Indica se trata-se de um campo chave
        .F.,;                                                                                       // [13]  L   Indica se o campo pode receber valor em uma operação de update.
        .F.)                                                                                        // [14]  L   Indica se o campo é virtual


 oStTRB:AddField(;
        "Nome",;                                                                                    // [01]  C   Titulo do campo
        "Nome Fornecedor",;                                                                         // [02]  C   ToolTip do campo
        "A2_NREDUZ",;                                                                                 // [03]  C   Id do Field
        TamSX3('A2_NREDUZ')[3],;                                                                      // [04]  C   Tipo do campo
        TamSX3('A2_NREDUZ')[1],;                                                                      // [05]  N   Tamanho do campo
        TamSX3('A2_NREDUZ')[1],;                                                                      // [06]  N   Decimal do campo
        Nil,;                                                                                       // [07]  B   Code-block de validação do campo
        Nil,;                                                                                       // [08]  B   Code-block de validação When do campo
        {},;                                                                                        // [09]  A   Lista de valores permitido do campo
        .F.,;                                                                                       // [10]  L   Indica se o campo tem preenchimento obrigatório
        FwBuildFeature( STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTRB+"->A2_NREDUZ,'')" ),;         // [11]  B   Code-block de inicializacao do campo
        .F.,;                                                                                       // [12]  L   Indica se trata-se de um campo chave
        .F.,;                                                                                       // [13]  L   Indica se o campo pode receber valor em uma operação de update.
        .F.)                                                                                        // [14]  L   Indica se o campo é virtual


 oStTRB:AddField(;
        "Nota Fiscal",;                                                                            // [01]  C   Titulo do campo
        "Nota Fiscal",;                                                                            // [02]  C   ToolTip do campo
        "D1_DOC",;                                                                                 // [03]  C   Id do Field
        TamSX3('D1_DOC')[3],;                                                                      // [04]  C   Tipo do campo
        TamSX3('D1_DOC')[1],;                                                                      // [05]  N   Tamanho do campo
        TamSX3('D1_DOC')[1],;                                                                      // [06]  N   Decimal do campo
        Nil,;                                                                                      // [07]  B   Code-block de validação do campo
        Nil,;                                                                                      // [08]  B   Code-block de validação When do campo
        {},;                                                                                       // [09]  A   Lista de valores permitido do campo
        .F.,;                                                                                      // [10]  L   Indica se o campo tem preenchimento obrigatório
        FwBuildFeature( STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTRB+"->D1_DOC,'')" ),;         // [11]  B   Code-block de inicializacao do campo
        .F.,;                                                                                      // [12]  L   Indica se trata-se de um campo chave
        .F.,;                                                                                      // [13]  L   Indica se o campo pode receber valor em uma operação de update.
        .F.)                                                                                       // [14]  L   Indica se o campo é virtual

 oStTRB:AddField(;
        "Quant Comprada",;                                                                            // [01]  C   Titulo do campo
        "Quant Comprada",;                                                                            // [02]  C   ToolTip do campo
        "D1_QUANT",;                                                                                 // [03]  C   Id do Field
        TamSX3('D1_QUANT')[3],;                                                                      // [04]  C   Tipo do campo
        TamSX3('D1_QUANT')[1],;                                                                      // [05]  N   Tamanho do campo
        TamSX3('D1_QUANT')[1],;                                                                      // [06]  N   Decimal do campo
        Nil,;                                                                                      // [07]  B   Code-block de validação do campo
        Nil,;                                                                                      // [08]  B   Code-block de validação When do campo
        {},;                                                                                       // [09]  A   Lista de valores permitido do campo
        .F.,;                                                                                      // [10]  L   Indica se o campo tem preenchimento obrigatório
        FwBuildFeature( STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTRB+"->D1_QUANT,'')" ),;         // [11]  B   Code-block de inicializacao do campo
        .F.,;                                                                                      // [12]  L   Indica se trata-se de um campo chave
        .F.,;                                                                                      // [13]  L   Indica se o campo pode receber valor em uma operação de update.
        .F.)        


oStTRB:AddField(;
        "Saldo Anterior",;                                                                            // [01]  C   Titulo do campo
        "Saldo Anterior",;                                                                            // [02]  C   ToolTip do campo
        "B2_SALDAT",;                                                                                 // [03]  C   Id do Field
        TamSX3('B2_QATU')[3],;                                                                      // [04]  C   Tipo do campo
        TamSX3('B2_QATU')[1],;                                                                      // [05]  N   Tamanho do campo
        TamSX3('B2_QATU')[1],;                                                                      // [06]  N   Decimal do campo
        Nil,;                                                                                      // [07]  B   Code-block de validação do campo
        Nil,;                                                                                      // [08]  B   Code-block de validação When do campo
        {},;                                                                                       // [09]  A   Lista de valores permitido do campo
        .F.,;                                                                                      // [10]  L   Indica se o campo tem preenchimento obrigatório
        FwBuildFeature( STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTRB+"->B2_SALDAT,'')" ),;         // [11]  B   Code-block de inicializacao do campo
        .F.,;                                                                                      // [12]  L   Indica se trata-se de um campo chave
        .F.,;                                                                                      // [13]  L   Indica se o campo pode receber valor em uma operação de update.
        .F.)        

 oStTRB:AddField(;
        "Saldo Estoque",;                                                                            // [01]  C   Titulo do campo
        "Saldo Estoque",;                                                                            // [02]  C   ToolTip do campo
        "B2_QATU",;                                                                                 // [03]  C   Id do Field
        TamSX3('B2_QATU')[3],;                                                                      // [04]  C   Tipo do campo
        TamSX3('B2_QATU')[1],;                                                                      // [05]  N   Tamanho do campo
        TamSX3('B2_QATU')[1],;                                                                      // [06]  N   Decimal do campo
        Nil,;                                                                                      // [07]  B   Code-block de validação do campo
        Nil,;                                                                                      // [08]  B   Code-block de validação When do campo
        {},;                                                                                       // [09]  A   Lista de valores permitido do campo
        .F.,;                                                                                      // [10]  L   Indica se o campo tem preenchimento obrigatório
        FwBuildFeature( STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTRB+"->B2_QATU,'')" ),;         // [11]  B   Code-block de inicializacao do campo
        .F.,;                                                                                      // [12]  L   Indica se trata-se de um campo chave
        .F.,;                                                                                      // [13]  L   Indica se o campo pode receber valor em uma operação de update.
        .F.)        


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
|Uso      |                                                                   | 
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
        "B1_CODBAR",;                 // [01]  C   Nome do Campo
        "03",;                      // [02]  C   Ordem
        "Cod Barras",;               // [03]  C   Titulo do campo
        "Cod Barras",;               // [04]  C   Descricao do campo
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
        "04",;                      // [02]  C   Ordem
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
        "B1_PICM",;               // [01]  C   Nome do Campo
        "05",;                      // [02]  C   Ordem
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
        "B1_MARKUP",;               // [01]  C   Nome do Campo
        "06",;                      // [02]  C   Ordem
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
        "DA1_PRCVEN",;              // [01]  C   Nome do Campo
        "07",;                      // [02]  C   Ordem
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
        "PRCSUG",;                  // [01]  C   Nome do Campo
        "08",;                      // [02]  C   Ordem
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
     

    oStTRB:AddField(;
        "DIFVALOR",;                // [01]  C   Nome do Campo
        "10",;                      // [02]  C   Ordem
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
        "D1_FORNECE",;              // [01]  C   Nome do Campo
        "11",;                      // [02]  C   Ordem
        "Fornecedor",;              // [03]  C   Titulo do campo
        "Fornecedor",;              // [04]  C   Descricao do campo
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
        "A2_NREDUZ",;                 // [01]  C   Nome do Campo
        "12",;                      // [02]  C   Ordem
        "Nome",;                    // [03]  C   Titulo do campo
        "Nome",;                    // [04]  C   Descricao do campo
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
        "D1_DOC",;                  // [01]  C   Nome do Campo
        "13",;                      // [02]  C   Ordem
        "Nota Fiacal",;             // [03]  C   Titulo do campo
        "Nota Fiscal",;             // [04]  C   Descricao do campo
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
        "B2_SALDAT",;                  // [01]  C   Nome do Campo
        "14",;                      // [02]  C   Ordem
        "Saldo Anterior",;             // [03]  C   Titulo do campo
        "Saldo Anterior",;             // [04]  C   Descricao do campo
        Nil,;                       // [05]  A   Array com Help
        "N",;                       // [06]  C   Tipo do campo
        "@E 9,999,999.99",;                      // [07]  C   Picture
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
        "D1_QUANT",;                  // [01]  C   Nome do Campo
        "15",;                      // [02]  C   Ordem
        "Quant Comprada",;             // [03]  C   Titulo do campo
        "Quantidade Comprada",;             // [04]  C   Descricao do campo
        Nil,;                       // [05]  A   Array com Help
        "N",;                       // [06]  C   Tipo do campo
        "@E 9,999,999.99",;                      // [07]  C   Picture
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
        "B2_QATU",;                  // [01]  C   Nome do Campo
        "16",;                      // [02]  C   Ordem
        "Saldo Atual",;             // [03]  C   Titulo do campo
        "Saldo Autal",;             // [04]  C   Descricao do campo
        Nil,;                       // [05]  A   Array com Help
        "N",;                       // [06]  C   Tipo do campo
        "@E 9,999,999.99",;                      // [07]  C   Picture
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
|Uso      |                                                                   | 
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

        dbSelectArea("SB2")
        SB2->(dbSetOrder(2))
        RecLock("TRB",.F.)
            TRB->B1_PICM    :=nICM
            TRB->PRCSUG     :=Round(((TRB->D1_VUNIT-(TRB->D1_VALDESC/TRB->D1_QUANT ))/((TRB->B1_MARKUP+nICM-100)/100))*-1,2)
            TRB->A2_NREDUZ  :=Posicione("SA2",1,xFilial("SA2")+TRB->D1_FORNECE+TRB->D1_LOJA,"A2_NREDUZ")
            IF SB2->(dbSeek(xFilial("SB2")+'01'+TRB->B1_COD))
                TRB->B2_QATU    :=SB2->B2_QATU-TRB->D1_QUANT
            Else
                TRB->B2_QATU    :=0
            EndIf

            IF Valtype(TRB->DA1_PRCVEN) <> 'U'
                TRB->DIFVALOR   :=Round((((TRB->D1_VUNIT-TRB->D1_VALDESC/TRB->D1_QUANT )/((TRB->B1_MARKUP+nICM-100)/100))*-1)-TRB->DA1_PRCVEN,2)
                TRB->DIFPERC    :=Round(((((TRB->D1_VUNIT-TRB->D1_VALDESC/TRB->D1_QUANT )/((TRB->B1_MARKUP+nICM-100)/100))*-1)/TRB->DA1_PRCVEN*100)-100,2)
            Else
                TRB->DIFVALOR   :=Round(((TRB->D1_VUNIT-TRB->D1_VALDESC/TRB->D1_QUANT )/((TRB->B1_MARKUP+nICM-100)/100))*-1,2)
                TRB->DIFPERC    :=100
            EndIF
            TRB->D1_VUNIT := TRB->D1_VUNIT-(TRB->D1_VALDESC/TRB->D1_QUANT )
            TRB->B2_SALDAT := TRB->B2_QATU-TRB->D1_QUANT
        msUnLock()
    EndIF
    TRB->(dbSkip())
EndDO

Return



/*
______________________________________________________________________________
|_____________________________________________________________________________|
|Programa  - AtuProd   Autor  Fabricio Antunes      Data   22/11/2020   	  |
|_____________________________________________________________________________|
|Descricao|Funcao para atualizar produtos com estrutura de desmontagem        |
|         |                                                                   |
|_________|___________________________________________________________________|
|Uso      |                                                                   | 
|_________|___________________________________________________________________|
|_____________________________________________________________________________|
*/

Static Function AtuProd
Local aDados:={}
Local aInf:={}
Local nX

TRB->(dbGoTop())
dbSelectArea("SB1")
SB1->((dbSetOrder(1)))

dbSelectArea("SG1")
SG1->(dbSetOrder(1))

While !TRB->(EOF())

    IF SG1->(dbSeek(xFilial("SG1")+TRB->B1_COD))
       

        dbSelectArea("SD3")
        SD3->(dbSetOrder(2))
        IF (dbSeek(xFilial("SD3")+TRB->D1_DOC+TRB->B1_COD))
            SD3->(dbGoTop())
            IF (dbSeek(xFilial("SD3")+TRB->D1_DOC))
                aDados:={}
                While !SD3->(EOF()) .AND. SD3->D3_FILIAL+SD3->D3_DOC = xFilial("SD3")+TRB->D1_DOC
                    IF SD3->D3_CF = 'DE7'
                        aadd(aDados,{SD3->D3_COD,SD3->D3_QUANT,SD3->D3_RATEIO})
                    EndIF
                    SD3->(dbSkip())
                EndDo
            EndIF
        Else
            MsgAlert("A nota fiscal de numero:" +TRB->D1_DOC+" possui o produto "+TRB->B1_COD+ " - "+TRB->B1_DESC+" que possui estrura mas a mesma ainda nao foi feito desmontagem!")
        EndIF
        
        aInf:={ TRB->D1_EMISSAO,;      //01
                TRB->D1_VUNIT,;        //02
                TRB->D1_FORNECE,;      //03
                TRB->D1_LOJA,;         //04
                TRB->A2_NREDUZ,;       //05
                TRB->D1_DOC,;          //06
                TRB->D1_RECNO,;        //07
                TRB->D1_DOC,;          //08
                TRB->D1_VALDESC}       //09
        RecLock("TRB",.F.)
            dbDelete()
        msUnLock()

        For nX:=1 to Len(aDados)
             SB1->(dbSeek(xFilial("SB1")+aDados[nX,1]))
            RecLock("TRB",.T.)
                TRB->B1_GRUPO   :=SB1->B1_GRUPO
                TRB->BM_DESC    :=Posicione("SBM",1,xFilial("SBM")+SB1->B1_GRUPO,"BM_DESC")
                TRB->B1_COD     :=SB1->B1_COD
                TRB->B1_DESC    :=SB1->B1_DESC
                TRB->B1_CODBAR  :=SB1->B1_CODBAR
                TRB->D1_EMISSAO :=aInf[1]
                TRB->D1_VUNIT   :=aInf[2]/100*aDados[nX,3]   
                dbSelectArea("DA1")
                DA1->(dbSetOrder(1))
                IF DA1->(dbSeek(xFilial("DA1")+Alltrim(GetMV("MV_TABPAD"))+SB1->B1_COD))
                    TRB->DA1_PRCVEN :=DA1->DA1_PRCVEN
                    TRB->DA1_RECNO  :=DA1->(Recno())
                Else
                    TRB->DA1_PRCVEN :=0
                    TRB->DA1_RECNO  :=0
                EndIF
                TRB->B1_MARKUP  :=SB1->B1_MARKUP
                TRB->D1_RECNO   :=aInf[7]
                TRB->D1_FORNECE :=aInf[3]
                TRB->D1_LOJA    :=aInf[4]
                TRB->D1_DOC     :=aInf[6]
                TRB->D1_VALDESC :=aInf[9]/100*aDados[nX,3]  
                TRB->D1_QUANT   :=aDados[nX,2]
            msUnLock()
        Next
    EndIF
    TRB->(dbSkip())
EndDO

Return


/*
______________________________________________________________________________
|_____________________________________________________________________________|
|Programa  - AtuProd   Autor  Fabricio Antunes      Data   22/11/2020   	  |
|_____________________________________________________________________________|
|Descricao|Funcao para atualizar produtos com estrutura de desmontagem        |
|         |                                                                   |
|_________|___________________________________________________________________|
|Uso      |                                                                   | 
|_________|___________________________________________________________________|
|_____________________________________________________________________________|
*/

Static Function Desmont
Local lEncon:=.F.

cQuery:=" SELECT * FROM "+RetSqlName("SF1")+" WHERE F1_DOC = '"+MV_PAR01+"' AND F1_SERIE = '"+MV_PAR02+"' "
cQuery+=" AND F1_FORNECE = '"+MV_PAR03+"' AND F1_LOJA = '"+MV_PAR04+"' AND D_E_L_E_T_ = ''"
dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"cSF1",.T.,.T.)

TRB->(dbGoTop())
While !TRB->(EOF())
       
            RecLock("TRB",.F.)
                TRB->D1_EMISSAO     :=Stod(cSF1->F1_EMISSAO)
                TRB->D1_VUNIT       :=cSF1->F1_VALBRUT*TRB->D3_RATEIO/100/TRB->D1_QUANT
                TRB->D1_RECNO       :=cSF1->R_E_C_N_O_
                TRB->D1_FORNECE     :=cSF1->F1_FORNECE
                TRB->D1_LOJA        :=cSF1->F1_LOJA
                TRB->A2_NREDUZ      :=POSICIONE("SA2",1,xFilial("SA2")+cSF1->F1_FORNECE,"A2_NREDUZ")
                TRB->D1_DOC         :=cSF1->F1_DOC
                TRB->D1_VALDESC     :=0
            TRB->(msUnLock())
    TRB->(dbSkip())
    lEncon:=.T.
EndDO

cSF1->(dbCloseArea())
Return lEncon




/*
______________________________________________________________________________
|_____________________________________________________________________________|
|Programa  - ImpRelpr   Autor  Fabricio Antunes      Data   08/02/2021        |
|_____________________________________________________________________________|
|Descricao|Funcao para impressao da precificacao                              |
|         |                                                                   |
|_________|___________________________________________________________________|
|Uso      |                                                                   | 
|_________|___________________________________________________________________|
|_____________________________________________________________________________|
*/
User Function ImpRelpr(lEnd)

Private oReport
Private oSecEmpre
Private oSecDados

If lEnd .and. MsgYesNo("Confirma Cancelar Atualização de Preços")
    Return
EndIf


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
|Uso      |                                                                   | 
|_________|___________________________________________________________________|
|_____________________________________________________________________________|
*/
Static Function ReportDef()


oReport := TReport():New("MFAT001","Precificacao          ",,{|oReport| PrintReport(oReport)},"Memória de cálculo tarefa 4")
oReport:SetLandscape(.T.) //Paisagem
//oReport:SetPortrait(.T.) //Retrato
oReport:lDisableOrientation := .T.
oReport:HideParamPage()//desabilita a impressão da pagina de parâmetros  

oReport:nFontBody:=9
//oReport:cFontBody:="Arial"

oSecEmpre := TRSection():New(oReport,"CABEC","SM0")
TRCell():New( oSecEmpre ,"RAZAO"			,"" ,"Razao Social" ,"@!"/*Picture*/	,   /*nSize*/,/*lPixel*/,/*bBlock*/,"LEFT"/*cAlign*/,/*lLineBreak*/,"LEFT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,.T./*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New( oSecEmpre ,"CNPJ"				,"" ,"CNPJ"			,"@!"/*Picture*/	,   /*nSize*/,/*lPixel*/,/*bBlock*/,"LEFT"/*cAlign*/,/*lLineBreak*/,"LEFT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,.T./*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New( oSecEmpre ,"FILIAL"			,"" ,"Filial Orig"	,"@!"/*Picture*/	,   /*nSize*/,/*lPixel*/,/*bBlock*/,"LEFT"/*cAlign*/,/*lLineBreak*/,"LEFT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,.T./*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)


oSecDados := TRSection():New(oReport,"PRODUTOS","TRB")
//TRCell():New(oSecDados	,"B1_GRUPO"			,"" ,"Grupo"		    ,X3Picture("B1_GRUPO")  ,   /*nSize*/,/*lPixel*/,/*bBlock*/,"LEFT"/*cAlign*/,/*lLineBreak*/,"LEFT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,.T./*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
//TRCell():New(oSecDados	,"BM_DESC"		    ,"" ,"Desc Grupo"	    ,X3Picture("BM_DESC")   ,   /*nSize*/,/*lPixel*/,/*bBlock*/,"LEFT"/*cAlign*/,/*lLineBreak*/,"LEFT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,.T./*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSecDados	,"B1_COD"			,"" ,"Codigo"	        ,X3Picture("B1_COD")	,   /*nSize*/,/*lPixel*/,/*bBlock*/,"LEFT"/*cAlign*/,/*lLineBreak*/,"LEFT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,.T./*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSecDados	,"B1_DESC"			,"" ,"Descricao"	    ,X3Picture("B1_DESC")	,   /*nSize*/,/*lPixel*/,/*bBlock*/,"LEFT"/*cAlign*/,/*lLineBreak*/,"LEFT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,.T./*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSecDados	,"B1_CODBAR"		,"" ,"Cod Barras"	    ,X3Picture("B1_CODBAR")	,   /*nSize*/,/*lPixel*/,/*bBlock*/,"LEFT"/*cAlign*/,/*lLineBreak*/,"LEFT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,.T./*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSecDados	,"D1_EMISSAO"		,"" ,"Emissao"	        ,X3Picture("D1_EMISSAO"),   /*nSize*/,/*lPixel*/,/*bBlock*/,"LEFT"/*cAlign*/,/*lLineBreak*/,"LEFT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,.T./*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSecDados	,"D1_VUNIT"			,"" ,"Preco Compra"	    ,X3Picture("D1_TOTAL")	,   /*nSize*/,/*lPixel*/,/*bBlock*/,"LEFT"/*cAlign*/,/*lLineBreak*/,"LEFT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,.T./*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSecDados	,"B1_MARKUP"		,"" ,"Markup"	        ,X3Picture("D1_TOTAL")	,   /*nSize*/,/*lPixel*/,/*bBlock*/,"LEFT"/*cAlign*/,/*lLineBreak*/,"LEFT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,.T./*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSecDados	,"B1_PICM"			,"" ,"Aliq ICM"		    ,X3Picture("B1_PICM")	,   /*nSize*/,/*lPixel*/,/*bBlock*/,"LEFT"/*cAlign*/,/*lLineBreak*/,"LEFT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,.T./*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSecDados	,"PRCSUG"	    	,"" ,"Preco Sugerido"	,X3Picture("D1_TOTAL")	,   /*nSize*/,/*lPixel*/,/*bBlock*/,"LEFT"/*cAlign*/,/*lLineBreak*/,"LEFT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,.T./*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSecDados	,"DA1_PRCVEN"		,"" ,"Preco Atual"		,X3Picture("D1_TOTAL"),   /*nSize*/,/*lPixel*/,/*bBlock*/,"LEFT"/*cAlign*/,/*lLineBreak*/,"LEFT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,.T./*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSecDados	,"DIFVALOR"			,"" ,"Dif Valor"		,X3Picture("D1_TOTAL")	,   /*nSize*/,/*lPixel*/,/*bBlock*/,"LEFT"/*cAlign*/,/*lLineBreak*/,"LEFT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,.T./*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSecDados	,"DIFPERC"			,"" ,"Dif Percen"		,X3Picture("B1_PICM")   ,   /*nSize*/,/*lPixel*/,/*bBlock*/,"LEFT"/*cAlign*/,/*lLineBreak*/,"LEFT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,.T./*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSecDados	,"D1_FORNECE"		,"" ,"Fornecedor"		,X3Picture("D1_FORNECE"),   /*nSize*/,/*lPixel*/,/*bBlock*/,"LEFT"/*cAlign*/,/*lLineBreak*/,"LEFT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,.T./*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
//TRCell():New(oSecDados	,"A2_NREDUZ"			,"" ,"Nome"		        ,X3Picture("A2_NREDUZ")	,   /*nSize*/,/*lPixel*/,/*bBlock*/,"LEFT"/*cAlign*/,/*lLineBreak*/,"LEFT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,.T./*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSecDados	,"D1_DOC"			,"" ,"Nota Fiscal"		,X3Picture("D1_DOC")    ,   /*nSize*/,/*lPixel*/,/*bBlock*/,"LEFT"/*cAlign*/,/*lLineBreak*/,"LEFT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,.T./*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSecDados	,"D1_QUANT"			,"" ,"Quant Comprad"	,X3Picture("D1_QUANT")    ,   /*nSize*/,/*lPixel*/,/*bBlock*/,"LEFT"/*cAlign*/,/*lLineBreak*/,"LEFT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,.T./*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSecDados	,"B2_QATU"			,"" ,"Saldo Autl"		,X3Picture("B2_QATU")    ,   /*nSize*/,/*lPixel*/,/*bBlock*/,"LEFT"/*cAlign*/,/*lLineBreak*/,"LEFT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,.T./*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)


oSecDados:SetLinesBefore(3)



Return(oReport)
/*
______________________________________________________________________________
|_____________________________________________________________________________|
|Programa  - PrintReport   Autor  Fabricio Antunes      Data   08/02/2021     |
|_____________________________________________________________________________|
|Descricao|Funcao responsavel pela impressao do relatório                     |
|         |                                                                   |
|_________|___________________________________________________________________|
|Uso      |                                                                   | 
|_________|___________________________________________________________________|
|_____________________________________________________________________________|
*/
Static Function PrintReport(oReport)


oSecEmpre:Init()
	dbSelectArea("SM0")
	SM0->(dbGotop())
	While !SM0->(EOF())
		IF SM0->M0_CODFIL = cFilant
			oSecEmpre:Cell("RAZAO"):SetValue(SM0->M0_NOMECOM)
			oSecEmpre:Cell("CNPJ"):SetValue(SM0->M0_CGC)
			oSecEmpre:Cell("FILIAL"):SetValue(SM0->M0_CODFIL)
			Exit
		EndIF
		SM0->(dbSkip())
	EndDo

oSecEmpre:PrintLine()
oSecEmpre:Finish()

oSecDados:Init()

TRB->(dbGoTop())

While !TRB->(Eof())

	If oReport:Cancel()
		Exit
	EndIf


    //oSecDados:Cell("B1_GRUPO"):SetValue(TRB->B1_GRUPO)
    //oSecDados:Cell("BM_DESC"):SetValue(TRB->BM_DESC)
    oSecDados:Cell("B1_COD"):SetValue(TRB->B1_COD)
    oSecDados:Cell("B1_DESC"):SetValue(SubStr(Alltrim(TRB->B1_DESC),1,30))
    oSecDados:Cell("B1_CODBAR"):SetValue(TRB->B1_CODBAR)
    oSecDados:Cell("D1_EMISSAO"):SetValue(TRB->D1_EMISSAO)
    oSecDados:Cell("D1_VUNIT"):SetValue(TRB->D1_VUNIT)
    oSecDados:Cell("B1_MARKUP"):SetValue(TRB->B1_MARKUP)
    oSecDados:Cell("B1_PICM"):SetValue(TRB->B1_PICM)
    oSecDados:Cell("PRCSUG"):SetValue(TRB->PRCSUG)
    oSecDados:Cell("DA1_PRCVEN"):SetValue(TRB->DA1_PRCVEN)
    oSecDados:Cell("DIFVALOR"):SetValue(TRB->DIFVALOR)
    oSecDados:Cell("DIFPERC"):SetValue(TRB->DIFPERC)
    oSecDados:Cell("D1_FORNECE"):SetValue(TRB->D1_FORNECE)
    //oSecDados:Cell("A2_NREDUZ"):SetValue(TRB->A2_NREDUZ)
    oSecDados:Cell("D1_DOC"):SetValue(TRB->D1_DOC)
    oSecDados:Cell("D1_QUANT"):SetValue(TRB->D1_QUANT)
    oSecDados:Cell("B2_QATU"):SetValue(TRB->B2_QATU)
       
	oSecDados:PrintLine()
	TRB->(dbSkip())
EndDo

oSecDados:Finish()
oReport:StartPage()
oReport:EndPage()

Return
