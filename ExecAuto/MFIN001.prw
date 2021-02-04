
#Include "Protheus.ch"
#Include "rwmake.ch"


User Function MFIN001()
	Private nOpc := 0
	Private cCadastro := "Importar arquivo CSV para importar convenios"
	Private aSay := {}
	Private aButton := {}
   
	AADD( aSay, "O objetivo desta rotina e efetuar a leitura em um arquivo csv para importar convenios," )
	AADD( aButton, { 1,.T.,{|| nOpc := 1,FechaBatch()}})
	AADD( aButton, { 2,.T.,{|| FechaBatch() }} )
  
	FormBatch( cCadastro, aSay, aButton )
	If nOpc == 1
 		Processa( {|| Import() }, "Processando..." )
	Endif
Return Nil      

//+-------------------------------------------
//| Função - Import()
//+-------------------------------------------
Static Function Import()
	Local cBuffer := ""
	Local cFileOpen := ""
	Local cTitulo1 := "Selecione o arquivo"
	Local cExtens := "Arquivo TXT | *.csv"
	Local cMainPath:="\SYSTEM\"
	Local aDados:={}
    Local aVetor := {}
    Local cPref  := ""
    Local cNatur := ""
    Local cIni   :=SubStr(dTos(dDatabase),3,6)
    Local cInc   :="000"
    Local cNum
    Private lMsErroAuto := .F.


	cFileOpen := cGetFile(cExtens,cTitulo1,,cMainPath,.T.)
   
	If !File(cFileOpen)
		MsgAlert("Arquivo texto: "+cFileOpen+" não localizado",cCadastro)
		Return
	Endif 
	
	FT_FUSE(cFileOpen) 
	FT_FGOTOP() 
   
          
    ProcRegua(FT_FLASTREC())
    While !FT_FEOF() 
        
        IncProc()

        cBuffer := FT_FREADLN() 
        aDados:=StrTokArr( cBuffer, ';' )
        /*
        1 - TIpo
        2 - C Custo
        3 - Cliente
        4 - Valor
        5 - Historico
        */

        dbSelectArea("SA1")
        SA1->(dbSetOrder(1))
        IF SA1->(dbSeek(xFilial("SA1")+aDados[3]))
            cInc:=Soma1(cInc)
            cNum:=cIni+Soma1(cInc)
            IF aDados[1] = '1'
                cPref   := 'CRF'
                cNatur  := '80103008'
            ElseIF aDados[1] = '2'
                cPref   := 'CAF'
                cNatur  := '80103008'
            ElseIF aDados[1] = '3'
                cPref   := 'CGA'
                cNatur  := '80103008'
            ElseIF aDados[1] = '4'
                cPref   := 'COD'
                cNatur  := '80103008'
            ElseIF aDados[1] = '5'
                cPref   := 'CUN'
                cNatur  := '80103008'
            ElseIF aDados[1] = '6'
                cPref   := 'CSI'
                cNatur  := '80103008'
            EndIF
            

            aVetor:={} 

            aaDD(aVetor,{"E1_PREFIXO"       ,cPref                      ,Nil})
            aaDD(aVetor,{"E1_NUM"           ,cNum                       ,Nil})
            aaDD(aVetor,{"E1_PARCELA"       ,'001'                      ,Nil})
            aaDD(aVetor,{"E1_TIPO"          ,'CO'                       ,Nil})
            aaDD(aVetor,{"E1_FILIAL"        ,xFilial("SE1")             ,Nil})
            aaDD(aVetor,{"E1_NATUREZ"       ,cNatur                     ,Nil})
            aaDD(aVetor,{"E1_CLIENTE"       ,SA1->A1_COD                ,Nil})
            aaDD(aVetor,{"E1_LOJA"          ,SA1->A1_LOJA               ,Nil})
            aaDD(aVetor,{"E1_EMISSAO"       ,dDatabase                  ,Nil})
            aaDD(aVetor,{"E1_VENCTO"        ,LastDate(dDataBase)        ,Nil})
            aaDD(aVetor,{"E1_VENCREA"       ,LastDate(dDataBase)        ,Nil})
            aaDD(aVetor,{"E1_VALOR"         ,Val(aDados[4])             ,Nil})
            aaDD(aVetor,{"E1_CCUSTO"        ,StrZero(Val(aDados[2]),8)  ,Nil})
            aaDD(aVetor,{"E1_HIST"          ,aDados[5]                  ,Nil})

            aVetor:=FWVetByDic(aVetor,"SE1",.F.)

            BEGIN TRANSACTION
                lMsErroAuto := .F.
                MSExecAuto({|x, y| FINA040(x, y)}, aVetor, 3)

                If lMsErroAuto
                    Alert("Falha ao realizar a inclusão do item, entre em contato com o suporte.")
                    MOSTRAERRO()
                    DisarmTransaction()
                EndIf
            END TRANSACTION
        Else
            MsgAlert("Funcionario "+aDados[3]+" nao encontado ba base, titulo nao sera importado.")
        EndIF
        FT_FSKIP() 
    EndDo

  
	FT_FUSE() 
             
Return Nil

