#INCLUDE "PROTHEUS.CH"
#INCLUDE "APWEBSRV.CH"
#INCLUDE "rwmake.ch"
#include "TbiConn.ch"
#include "TbiCode.ch"
#INCLUDE "XMLXFUN.CH" 
#INCLUDE "protheus.ch"   
#include "shell.ch"

#DEFINE VALIDAORIGEM	"12345678910" 

/*
#############################################################################
||-------------------------------------------------------------------------||
||Metodo     |WSFLGSRV  |Fabricio Antunes            | Data  22/05/19      ||
||-------------------------------------------------------------------------||
||Desc.      | WebService para integracao de liberacao de PC vindos do     ||
||           | Fluig                                                       ||
||-------------------------------------------------------------------------||
||Uso        |                                                           ||
||-------------------------------------------------------------------------||
#############################################################################
*/


WsService WSFLGSRV Description "Servio de Integrao Aprovao de          Protheus Fluig " // NAMESPACE "srv007:8585"  //METODO QUE CRIA INSTANCIA DO WS
//VARIAVEIS RECEBIDAS

	WSDATA cWSChave as String 
	WSDATA cWSUser as String
	WSDATA cWSSolic  as String
	WSDATA cWSAprova as String 
	WSData cEmpFil	as String
	WsData cRec as String
  

	WSData cWSRetur   as String    //VARIAVEL RETORNO QUE SOMENTE TERA DOIS ESTADO OPERACAO REALIZADA OU OPERAO NO REALIZADA  1/PARA REALIADAO , 0/PARA NO REAIZADA                                     


	//RELAO DE METODOS DO WEBSERVICES 
	WsMethod Integra Description "METODO CRIADO PARA RECEBER AS INFORMAES PASSADAS PELO FLUIG E MOVIMENTAR  A APROVAO OU REPROVAO DO PEDIDO DE COMPRA V2"  


EndWsService
/*
#############################################################################
||-------------------------------------------------------------------------||
||Metodo     |Integra   |Fabricio Antunes            | Data  22/05/19      ||
||-------------------------------------------------------------------------||
||Desc.      | Metodo para integracao da resposta do fluig vinda do        ||
||           | WebService WSFLGSRV                                         ||
||-------------------------------------------------------------------------||
||Uso       |                                                           ||
||-------------------------------------------------------------------------||
#############################################################################
*/

WsMethod Integra WsReceive cWSChave, cWSUser, cWSSolic, cWSAprova, cEmpFil, cRec  WsSend cWSRetur WsService WSFLGSRV

Local cChave //CHAVE DE VALIDAO ORIGEM
Local cUser //RECEBE O ESTADO
Local cSolict
Local cAproRep
Local cEmpFil
Private cEmp
Private cFill
Private nRec

conOut("WEBSERVICE INSTANCIADO POR CLIENTE...")
conOut("Iniciando Primeira Etapa")
conOut("Capturando Variaveis... Recebendo Variaveis Emviadas via SOAP de FLUIG")

//Atribuo as variavis para trabalhar no Protheus

 cChave :=  ::cWSChave
 cUser  :=  ::cWSUser
 cSolict := PadR(::cWSSolic,50)
 cAproRep:= ::cWSAprova
 cEmpFil:=	::cEmpFil
 cEmp:=	SubStr(cEmpFil,1,2)
 cFill:=SubStr(cEmpFil,3,4)
 nRec:=Val(::cRec)
 
conOut("Montando Vetor de Procesamento... Alimentando Vetor de dados para o processamento")

RPCSetType(3) // Tipo 3 nao consome licenca
PREPARE ENVIRONMENT EMPRESA cEmp FILIAL cFill

if cChave == "12345678910"

	conOut("Origem OK... Iniciando o processo de Movimentaes.. ")  
	 U_BXSOPRH(cSolict,cAproRep,cUser )
	::cWSRetur := "1;0001 -Operao Realizada Corretamente!!!" //RETORNO DE OPERAO CONCLUIDA
			             
Else
	conOut("Chave de segurana invlida!")
	::cWSRetur := "0;0000 -CHAVE DE SEGURANA INVALIDA" //RETORNO DE OPERAO NO CONCLUIDA

EndIf


Return(.T.)

/*
#############################################################################
||-------------------------------------------------------------------------||
||Programa  |BXSOPRH   |Fabricio Antunes            | Data  22/05/19    ||
||-------------------------------------------------------------------------||
||Desc.      | Funcao para integracao da resposta do fluig vinda do        ||
||           | WebService                                                  ||
||-------------------------------------------------------------------------||
||Uso     |                                                             ||
||-------------------------------------------------------------------------||
#############################################################################
*/
User Function BXSOPRH(cSolict,cAproRep,cUser )

Local aLib:={}
Local nValor:=0
Local lExecut 	:= SuperGetMV("CR_FLUIG",.F.,.F.)      			 // Habilita integracao Fluig
Local cTipo
Local cTpLiber
Local nX
Local cNivel := ""

cSolict:=SubStr(cSolict,8,Len(cSolict))

IF lExecut
	If Alltrim(cAproRep)=="Reprovado"	
		
		// Posiciona a Boqueio
		DBSelectarea("SCR")                   
		SCR->(DBSetorder(2))
		dbGoTo(nRec)  //CR_FILIAL+CR_TIPO+CR_NUM+CR_USER

		IF SCR->CR_WF == ''
			RecLock("SCR",.F.)
				SCR->CR_WF := '2'
			msUnLock()
			Return
		EndIF


		ConOut("BLOQUEIO DE SOLICITAAO DE COMPRA")
		RecLock("SCR",.f.)
			SCR->CR_DataLib := dDataBase
			SCR->CR_Obs     := "" //DEVO PEGAR A OBS DO FLUIG
			SCR->CR_STATUS  := "04"  //Bloqueado
			SCR->CR_XIDFLU	:= ""
		MsUnLock()
		
		cTipoDc:=SCR->CR_TIPO
		
		//Bloqueia no pedido
		dbselectarea("SC7")
		SC7->(DBSETORDER(1))
		IF SC7->(DBSeek(cFill+Alltrim(cSolict)))      // Posiciona o Pedido)
			While !EOF() .and. SC7->C7_Num == Alltrim(cSolict)
				RecLock("SC7",.f.)
					SC7->C7_XMOTIVO	:= "A SOLICITAO FOI BLOQUEADA VIA FLUIG..."
				MsUnLock()
				SC7->(DBSkip())
			Enddo
		EndIF

		//Exclui para outros aprovadores no Fluig
		If SCR->(DBSeek(cFill+cTipoDc+cSolict))
			While !SCR->(EOF()) .AND. SCR->CR_FILIAL+SCR->CR_TIPO+SCR->CR_NUM = cFill+cTipoDc+cSolict
				IF SCR->CR_XIDFLU	<>  ""
					//Chama funcao de delecaodo Fluig
					U_M120FM01(SCR->CR_XIDFLU)
				EndIF
				RecLock("SCR",.F.)
					SCR->CR_DataLib := dDataBase
					SCR->CR_Obs     := "BLOQUEADO POR OUTRO USUARIO VIA FLUIG" //
					SCR->CR_STATUS  := "06"
					SCR->CR_XIDFLU	:= ""
				msUnLock()
				SCR->(dbSkip())
			EndDo
		EndIf 

	ElseIf alltrim(cAproRep)=="Aprovado"

		//-------------------------------------------------------------------
		// Controle de Aprovacao : CR_STATUS                
		// 01 - Bloqueado p/ sistema (aguardando outros niveis) 
		// 02 - Aguardando Liberacao do usuario                 
		// 03 - Pedido Liberado pelo usuario                    
		// 04 - Pedido Bloqueado pelo usuario                   
		// 05 - Pedido Liberado por outro usuario               
		// 06 - Documento Rejeitado
		//-------------------------------------------------------------------

		dbSelectarea("SCR") 
		SCR->(DBSetorder(2))
		dbGoTo(nRec)
		
		IF Alltrim(SCR->CR_WF) == ''
			RecLock("SCR",.F.)
				SCR->CR_WF := '2'
			msUnLock()
			Return
		EndIF

		cTipoDc:=SCR->CR_TIPO

		dbSelectArea("SAL")
		SAL->(dbSetOrder(3))

		IF SAL->(dbSeek(xFilial("SAL")+SCR->CR_GRUPO+SCR->CR_APROV))
			cTipo		:=SAL->AL_LIBAPR
			cTpLiber	:=SAL->AL_TPLIBER
		EndIF

		conout("LIBERANDO SOLICITAO DE COMPRAS")
		RecLock("SCR",.f.)
			SCR->CR_DataLib := dDataBase
			SCR->CR_Obs     := "LIBERADO VIA FLUIG" //
			SCR->CR_STATUS  := "03"
			SCR->CR_USERLIB	:= SCR->CR_USER
			SCR->CR_LIBAPRO	:= SCR->CR_APROV
			SCR->CR_XIDFLU = ""
		MsUnLock()
		cNivel	:= SCR->CR_NIVEL
		cUserA	:= SCR->CR_USER
		cAprov	:= SCR->CR_APROV

		//Verifica se tem fluig para mesmo nivel para ser deletado caso oaprovador seja por ni­vel ou or documento
		IF (cTpLiber = 'N' .OR. cTpLiber = 'P') .AND. cTipo = 'A'
			If SCR->(DBSeek(cFill+cTipoDc+cSolict))
				While !SCR->(EOF()) .AND. SCR->CR_FILIAL+SCR->CR_TIPO+SCR->CR_NUM = cFill+cTipoDc+cSolict
					IF SCR->CR_STATUS = '02' .AND. SCR->CR_NIVEL = cNivel
						IF Alltrim(SCR->CR_XIDFLU) <> ""
							//Chama funcao de delecao do Fluig para o mesmo ni­vel
							U_M120FM01(SCR->CR_XIDFLU)
						EndIF
						//Altera o status dos outros aprovadores do mesmo ni­vel
						RecLock("SCR",.F.)
							SCR->CR_DataLib := dDataBase
							SCR->CR_Obs     := "LIBERADO POR OUTRO USUARIO VIA FLUIG" //
							SCR->CR_STATUS  := "05"
							SCR->CR_USERLIB	:= cUserA
							SCR->CR_LIBAPRO	:= cAprov
							SCR->CR_XIDFLU = ""
						msUnLock()
					EndIf
					SCR->(dbSkip())
				EndDo
			EndIf 
		EndIF

		//Verifica se tem proximo ni­vel para envio
		If SCR->(DBSeek(cFill+cTipoDc+cSolict))
			While !SCR->(EOF()) .AND. SCR->CR_FILIAL+SCR->CR_TIPO+SCR->CR_NUM = cFill+cTipoDc+cSolict
				IF (SCR->CR_STATUS = '01' .OR. SCR->CR_STATUS = '02') .AND. SCR->CR_NIVEL <> cNivel
					aadd(aLib,{SCR->CR_USER, SCR->CR_NIVEL,SCR->CR_STATUS,SCR->(Recno())})
				EndIf
				SCR->(dbSkip())
			EndDo
		EndIf 
		
		//Se nao tiver mais niveis ou for aprovacao por documento para aprovar libera o pedido 
		IF (Len(aLib) = 0 .OR. cTpLiber = 'P') .AND. cTipo = 'A'
			dbselectarea("SC7")
			SC7->(DBSETORDER(1))
			IF SC7->(DBSeek(cFill+Alltrim(cSolict)))  
				While !SC7->(EOF()) .AND. SC7->C7_NUM = Alltrim(cSolict)
					RecLock("SC7",.F.)
						SC7->C7_CONAPRO := "L"
						SC7->C7_XMOTIVO := "A SOLICITAO FOI LIBERADA VIA FLUIG..."
						SC7->C7_APROV	:= cUser
					MsUnLock()
					nValor+=SC7->C7_TOTAL
					SC7->(DBSkip())
				Enddo
			EndIf
		Else
			ASORT(aLib, , , { | x,y | x[2] < y[2] } )
			cNivel:=  aLib[1,2]
			For nX:=1 to Len(aLib)
				IF aLib[nX,3] = '01' .AND. cNivel =  aLib[nX,2]
					SCR->(dbGoto(aLib[nX,4]))
					RecLock("SCR",.F.)
						SCR->CR_STATUS  := "02"
					MsUnLock()
					cNivel:=  aLib[nX,2]			
				EndIF
			Next
			dbSelectArea("SC7")
			SC7->(dbSetOrder(1))
			IF SC7->(dbSeek(cFill+Alltrim(cSolict)))
				//Chama funcao para abrir BPM para proximo nivel no Fluig
				U_MRQWS01A(cTipoDc,cUser)
			EndIF
		EndIF	

	EndIf
EndIF

Return

/*
#############################################################################
||-------------------------------------------------------------------------||
||Programa   |MRQWS01A  |Fabricio Antunes            | Data  09/12/20      ||
||-------------------------------------------------------------------------||
||Desc.      | Funcao para gerar nova integracao com o fluig para nivel    ||
||           | superior de aprovacao do pedido de                          ||
||-------------------------------------------------------------------------||
||Uso        |                                                             ||
||-------------------------------------------------------------------------||
#############################################################################
*/
User Function MRQWS01A(cTipoDc,cAprov)

Local cusername := Alltrim(SuperGetMV("CR_FLUSR",.F.,"user"))      	 // USUARIO INTEGRADOR       		
Local cpassword := Alltrim(SuperGetMV("CR_FLPSW",.F.,"senha")) 	 //SENHA USUARIO INTEGRADOR 		
Local cURL		:= Alltrim(SuperGetMV("CR_FLURL",.F.,"https://seufluig.fluig.com"))  //URL Fluig
Local lExecut 	:= SuperGetMV("CR_FLUIG",.F.,.F.)      			 		// Habilita integracao Fluig
Local ncompanyId := Alltrim(SuperGetMV("CR_FLCOM",.F.,'1')) 			//CODIGO COMPANIA
Local cprocessId := Alltrim(SuperGetMV("CR_FLPRO",.F.,"000001"))        //Codigo do processo
Local nchoosedState	:=  '2'			//Stado de iniciao do prcesso no fluig	
Local nOpcA     := 1
Local cComments	 := "Integracao via Protheus - realizada em: "+dtoc(DATE())+" "
Local oWsdl
Local xRet
Local aComplex := {}
Local aSimple := {}
Local aEnvia	:={}
Local nPos := 0, nOccurs := 0
Local aValues:={} 
Local aUser:={}
Local cPedaco
Local cPosIni
Local cID, nX
Private _cSolici := SC7->C7_NUM 
Private _cFillx	 := SC7->C7_FILIAL
Private _cEmissa := SC7->C7_EMISSAO
Private _cFornec := SC7->C7_FORNECE
Private _cTipo	 := cTipoDc
Private _cCondPa := Alltrim(SC7->C7_COND) + " - "+Alltrim(Posicione("SE4",1,xFilial("SE4")+Alltrim(SC7->C7_COND),"E4_DESCRI"))
Private _cForNom := Posicione("SA2",1,xFilial("SA2") + SC7->C7_FORNECE + SC7->C7_LOJA,"A2_NREDUZ") 
Private _cTotImp := 0
Private _cItmSl
Private _cUser	:= cAprov
Private cMoeda	

IF SC7->C7_MOEDA = 1
	cMoeda:="R$"
ElseIF SC7->C7_MOEDA = 2
	cMoeda:="US$"
Else
	cMoeda:="$"	
EndIF

_cItmSl := U_GeraHTML()

If lExecut
	If nOpcA = 1
		dbSelectArea("SCR")
		SCR->(dbSetOrder(1))
		IF SCR->(dbSeek(cFill+_cTipo+_cSolici))
		
	
			While !SCR->(EOF()) .AND. SCR->CR_FILIAL+_cTipo+SCR->CR_NUM = cFill+_cTipo+_cSolici
				IF SCR->CR_STATUS = '02'
					aadd(aUser,{SCR->CR_USER, SCR->CR_NIVEL,Recno()})
				EndIF
				SCR->(dbSkip())
			EndDo
			IF Len(aUser) > 0
			
				ASORT(aUser, , , { | x,y | x[2] < y[2] } )

				For nX:= 1 to Len(aUser)
					IF nX = 1
							aaDD(aEnvia,aUser[1])
					else
						IF aEnvia[1,2] = aUser[nX,2]   
						aaDD(aEnvia,aUser[nX])
						EndIF
					EndIF
				Next

			 	For nX:=1 to Len(aEnvia)
					cUser:=Alltrim(aEnvia[nX,1])
					nRec:=aEnvia[nX,3]

					
					//oWs := WSECMWorkflowEngineServiceService():New()
					oWsdl := TWsdlManager():New()
					oWSDL:nTimeout      := 1000 // TEMPO DE ESPERA PARA RESPOSTA
					oWSDL:lVerbose      := .T.  // HABILITA O REGISTRO DOS COMANDOS ENVIADOS E RECEBIDOS
					oWSDL:lSSLInsecure  := .T.  // REALIZA A CONEXO SSL DE FORMA ANNIMA
					oWsdl:lRemEmptyTags := .T.  // REMOVE TAGS VAZIAS
					
				
					xRet := oWsdl:ParseURL( cURL+"/webdesk/ECMWorkflowEngineService?wsdl" )
						if xRet == .F.
						cErro:=oWsdl:cError 
						Return
					endif
					
					xRet := oWsdl:SetOperation( "startProcess" )
					
					if xRet == .F.
						cErro:=oWsdl:cError 
						Return
					endif
					
					//Objetos Complexos
					aComplex := oWsdl:NextComplex()
					
					while ValType( aComplex ) == "A"
						varinfo( "aComplex", aComplex )
					
						if ( aComplex[2] == "item" ) .And. ( aComplex[5] == "attachments#1" )
							nOccurs := 0
						elseif ( aComplex[2] == "item" ) .And. ( aComplex[5] == "cardData#1" )
							nOccurs := 13
						elseif ( aComplex[2] == "item" ) .And. ( aComplex[5] == "appointment#1" )
							nOccurs := 0
						else
							nOccurs := 0
						endif
			
						xRet := oWsdl:SetComplexOccurs( aComplex[1], nOccurs )
						
						if xRet == .F.
							conout( "Erro ao definir elemento " + aComplex[2] + ", ID " + cValToChar( aComplex[1] ) + ", com " + cValToChar( nOccurs ) + " ocorrencias" )
							cErro:= "Erro ao definir elemento " + aComplex[2] + ", ID " + cValToChar( aComplex[1] ) + ", com " + cValToChar( nOccurs ) + " ocorrencias"
							Return
						Endif
						
						aComplex := oWsdl:NextComplex()
					EndDo
					
					//Objetos simples
					aSimple := oWsdl:SimpleInput()
					varinfo( "aSimple", aSimple )
					
					nPos:=0 
					nPos := aScan( aSimple, {|aVet| aVet[2] == "username" .AND. aVet[5] == "username" } )
					IF nPos > 0
						xRet := oWsdl:SetValue( aSimple[nPos][1], cusername )
					EndIF
					
					nPos:=0	 
					nPos := aScan( aSimple, {|aVet| aVet[2] == "password" .AND. aVet[5] == "password" } )
					IF nPos > 0
						xRet := oWsdl:SetValue( aSimple[nPos][1], cpassword ) 
					EndIF
					
					nPos:=0
					nPos := aScan( aSimple, {|aVet| aVet[2] == "companyId" .AND. aVet[5] == "companyId" } )
					IF nPos > 0
						xRet := oWsdl:SetValue( aSimple[nPos][1], ncompanyId ) 		
					EndIF
					
					nPos:=0
					nPos := aScan( aSimple, {|aVet| aVet[2] == "processId" .AND. aVet[5] == "processId" } )
					IF nPos > 0
						xRet := oWsdl:SetValue( aSimple[nPos][1], cprocessId ) 	
					EndIF
					
					nPos:=0
					nPos := aScan( aSimple, {|aVet| aVet[2] == "choosedState" .AND. aVet[5] == "choosedState" } )
					IF nPos > 0
						xRet := oWsdl:SetValue( aSimple[nPos][1], nchoosedState ) 	
					EndIF
					
					nPos:=0
					nPos := aScan( aSimple, {|aVet| aVet[2] == "item" .AND. aVet[5] == "colleagueIds#1" } )
					IF nPos > 0
						xRet := oWsdl:SetValue( aSimple[nPos][1], cUser ) 	
					EndIF
							
					
					nPos:=0
					nPos := aScan( aSimple, {|aVet| aVet[2] == "comments" .AND. aVet[5] == "comments" } )
					IF nPos > 0
						xRet := oWsdl:SetValue( aSimple[nPos][1], cComments ) 	
					EndIF
					
					nPos:=0
					nPos := aScan( aSimple, {|aVet| aVet[2] == "userId" .AND. aVet[5] == "userId" } )
					IF nPos > 0
						xRet := oWsdl:SetValue( aSimple[nPos][1], cusername ) 	
					EndIF
					
					nPos:=0
					nPos := aScan( aSimple, {|aVet| aVet[2] == "completeTask" .AND. aVet[5] == "completeTask" } )
					IF nPos > 0
						xRet := oWsdl:SetValue( aSimple[nPos][1], "true") 	
					EndIF
					
					nPos:=0
					nPos := aScan( aSimple, {|aVet| aVet[2] == "managerMode" .AND. aVet[5] == "managerMode" } )
					IF nPos > 0
						xRet := oWsdl:SetValue( aSimple[nPos][1], "true" )		
					EndIF
			
					aValues:={"edt_pedido",ALltrim(_cFillx)+" - "+_cSolici}
					nPos:=0
					nPos := aScan( aSimple, {|aVet| aVet[2] == "item" .AND. aVet[5] == "cardData#1.item#1"} )
					IF nPos > 0
						xRet := oWsdl:SetValues( aSimple[nPos][1], aValues) 	
					EndIF
					
					aValues:={"txt_prioridade","Alta"}
					nPos:=0
					nPos := aScan( aSimple, {|aVet| aVet[2] == "item" .AND. aVet[5] == "cardData#1.item#2"} )
					IF nPos > 0
						xRet := oWsdl:SetValues( aSimple[nPos][1], aValues) 	
					EndIF
					
					
					aValues:={"edt_solic",Alltrim(UsrFullName(_cUser))}
					nPos:=0
					nPos := aScan( aSimple, {|aVet| aVet[2] == "item" .AND. aVet[5] == "cardData#1.item#3"} )
					IF nPos > 0
						xRet := oWsdl:SetValues( aSimple[nPos][1], aValues) 	
					EndIF
					
					
					aValues:={"edt_fornecedor",_cFornec+" - "+_cForNom}
					nPos:=0
					nPos := aScan( aSimple, {|aVet| aVet[2] == "item" .AND. aVet[5] == "cardData#1.item#4"} )
					IF nPos > 0
						xRet := oWsdl:SetValues( aSimple[nPos][1], aValues) 	
					EndIF
					
					
					aValues:={"txt_data",DTOC(_cEmissa)}
					nPos:=0
					nPos := aScan( aSimple, {|aVet| aVet[2] == "item" .AND. aVet[5] == "cardData#1.item#5"} )
					IF nPos > 0
						xRet := oWsdl:SetValues( aSimple[nPos][1], aValues) 	
					EndIF
					
					
					aValues:={"edt_condpag",_cCondPa}
					nPos:=0
					nPos := aScan( aSimple, {|aVet| aVet[2] == "item" .AND. aVet[5] == "cardData#1.item#6"} )
					IF nPos > 0
						xRet := oWsdl:SetValues( aSimple[nPos][1], aValues) 	
					EndIF
					
					
					aValues:={"txt_info",'<![CDATA['+rtrim(_cItmSl)+']]>'}
					nPos:=0
					nPos := aScan( aSimple, {|aVet| aVet[2] == "item" .AND. aVet[5] == "cardData#1.item#7"} )
					IF nPos > 0
						xRet := oWsdl:SetValues( aSimple[nPos][1], aValues) 	
					EndIF
					
					
					aValues:={"edt_adic",_cTotImp}
					nPos:=0
					nPos := aScan( aSimple, {|aVet| aVet[2] == "item" .AND. aVet[5] == "cardData#1.item#8"} )
					IF nPos > 0
						xRet := oWsdl:SetValues( aSimple[nPos][1], aValues) 	
					EndIF

					aValues:={"edt_fil",cEmpAnt+cFilAnt}
					nPos:=0
					nPos := aScan( aSimple, {|aVet| aVet[2] == "item" .AND. aVet[5] == "cardData#1.item#9"} )
					IF nPos > 0
						xRet := oWsdl:SetValues( aSimple[nPos][1], aValues) 	
					EndIF	
							
					aValues:={"cmb_aprovar","Aprovado"}
					nPos:=0
					nPos := aScan( aSimple, {|aVet| aVet[2] == "item" .AND. aVet[5] == "cardData#1.item#10"} )
					IF nPos > 0
						xRet := oWsdl:SetValues( aSimple[nPos][1], aValues) 	
					EndIF	
					
					aValues:={"nrecno",Alltrim(Str(nRec))}
					nPos:=0
					nPos := aScan( aSimple, {|aVet| aVet[2] == "item" .AND. aVet[5] == "cardData#1.item#11"} )
					IF nPos > 0
						xRet := oWsdl:SetValues( aSimple[nPos][1], aValues) 	
					EndIF	

					aValues:={"cimport",'N'}
					nPos:=0
					nPos := aScan( aSimple, {|aVet| aVet[2] == "item" .AND. aVet[5] == "cardData#1.item#12"} )
					IF nPos > 0
						xRet := oWsdl:SetValues( aSimple[nPos][1], aValues) 	
					EndIF	

					
					aValues:={"usuario",cUser}
					nPos:=0
					nPos := aScan( aSimple, {|aVet| aVet[2] == "item" .AND. aVet[5] == "cardData#1.item#13"} )
					IF nPos > 0
						xRet := oWsdl:SetValues( aSimple[nPos][1], aValues) 	
					EndIF	
					


					cMessege:=oWsdl:GetSoapMsg()
					
					//Retirado o elemento da tag devido o obj nao suportar
					cMessege := StrTran(cMessege, ' xmlns="http://ws.dm.ecm.technology.totvs.com/"', '')
					cMessege := StrTran(cMessege, "<?xml version='1.0' encoding='UTF-8' standalone='no' ?>", '')
			
					cMessege:=EncodeUTF8(cMessege)
			
					oWsdl:lProcResp := .F. //No processa o retorno automaticamente no objeto (sertratado atravs do mtodo GetSoapResponse)
					lRet := oWsdl:SendSoapMsg(cMessege)
					cError:=oWsdl:cError
					cError:=cError
					
					If lRet
						//Trata a resposta do WebService
						cXmlRet := oWsdl:GetSoapResponse()
						If ! Empty( cXmlRet )
							cPosIni:= At("<item>iProcess</item><item>",cXmlRet) 
							IF cPosIni > 0
								cPedaco:= SubStr(cXmlRet,cPosIni+27,20)
								cPosIni:= At("</item>",cPedaco)
								cID:=SubStr(cPedaco,1,cPosIni-1)
								dbSelectArea("SCR")
								SCR->(dbGoTo(nRec))
								RecLock("SCR",.F.)
									SCR->CR_XIDFLU:=cID
								msUnLock()
								lRet:=.T.
							Else
								lRet:=.F.
							EndIf
						Else
							lRet:=.F.
						Endif
					Else
						lRet:=.F.
					Endif
				Next nX

			Endif
		EndIF
	EndIF
EndIf

Return (lRet)
/*
#############################################################################
||-------------------------------------------------------------------------||
||Programa  |GeraHTML  |Fabricio Antunes            | Data  22/05/19       ||
||-------------------------------------------------------------------------||
||Desc.      | Funcao estatica para gercao de codigo html para itens do    ||
||           | pedido de                                                   ||
||-------------------------------------------------------------------------||
||Uso       |                                                              ||
||-------------------------------------------------------------------------||
#############################################################################
*/
User Function GeraHTML()

Local cFlaLine		:= "0"
Local cColorLi		:= " "
Local xArea:=GetArea("SC7")
Local cNum:=SC7->C7_NUM
Local cFill:=SC7->C7_FILIAL

//C7_FORNECE, C7_LOJA, C7_NUM, C7_EMISSAO
//MONTAGEM DO HTML
cHtml:=" "

cHtml += '  <table width="100%" border="0" class="table" style="width: 100%">'	+ CRLF
cHtml += '   <thead>'															+ CRLF
cHtml += '    <tr style="background: #B0B0B0">'									+ CRLF
cHtml += '     <th width="5%"><b>Item</b></th>'									+ CRLF
cHtml += '     <th width="10%"><b>Cod. Produto</b></th>'						+ CRLF
cHtml += '     <th width="35%"><b>Descri&ccedil;&atilde;o</b></th>'				+ CRLF
cHtml += '     <th width="8%"><b>Un. Med</b></th>'								+ CRLF
cHtml += '     <th width="8%"><b>Quantidade</b></th>'							+ CRLF
cHtml += '     <th width="8%"><b>Vlr. Unit</b></th>'							+ CRLF
cHtml += '     <th width="8%"><b>Vlr. Total</b></th>'							+ CRLF
cHtml += '     <th width="8%"><b>Desconto</b></th>'								+ CRLF
cHtml += '     <th width="8%"><b>Vlr. Liquido</b></th>'							+ CRLF
cHtml += '     <th width="10%"><b>Cen. Custo</b></th>'							+ CRLF
cHtml += '    </tr>'															+ CRLF
cHtml += '   </thead>'															+ CRLF
cHtml += '   <tbody>'															+ CRLF

While !SC7->(EOF()) .AND. SC7->C7_FILIAL+SC7->C7_NUM = cFill+cNum
	
	cItem 		:=	SC7->C7_ITEM
	cProdut		:=	SC7->C7_PRODUTO
	nQuant		:=	SC7->C7_QUANT
	cDescr		:=	SC7->C7_DESCRI
	cUnMed		:=	SC7->C7_UM
	cVlrUn		:=  SC7->C7_PRECO
	nVlrTotal	:=	SC7->C7_TOTAL
	nDesc		:=  SC7->C7_VLDESC
	cCC			:= 	Posicione("CTT",1,xFilial("CTT")+SC7->C7_CC,"CTT_DESC01")


	_cTotImp += nVlrTotal-nDesc
	
If cFlaLine == "0" 
		cColorLi := "#EEEEEE"  
		
		cHtml += '   <tr style="background: '+cColorLi+'">'	+ CRLF
		cHtml += '     <td>'+ALLTRIM(cItem)+'</td>'			+ CRLF
		cHtml += '     <td>'+ALLTRIM(cProdut)+'</td>'		+ CRLF
		cHtml += '     <td>'+ALLTRIM(cDescr)+'</td>'		+ CRLF
		cHtml += '     <td>'+ALLTRIM(cUnMed)+'</td>'		+ CRLF
		cHtml += '     <td>'+U_picVal(cValToChar(nQuant),"")+'</td>'		+ CRLF
		cHtml += '     <td>'+U_picVal(cValToChar(cVlrUn),cMoeda)+'</td>'		+ CRLF
		cHtml += '     <td>'+U_picVal(cValToChar(nVlrTotal),cMoeda)+'</td>'		+ CRLF
		cHtml += '     <td>'+U_picVal(cValToChar(nDesc),cMoeda)+'</td>'			+ CRLF
		cHtml += '     <td>'+U_picVal(cValToChar(nVlrTotal-nDesc),cMoeda)+'</td>'			+ CRLF
		cHtml += '     <td>'+ALLTRIM(cCC)+'</td>'			+ CRLF
		cHtml += '   </tr>'									+ CRLF
															
		cFlaLine := "1"
	Else
		cColorLi := "#FFFFFF"
		
		cHtml += '   <tr style="background: '+cColorLi+'">'	+ CRLF
		cHtml += '     <td>'+ALLTRIM(cItem)+'</td>'			+ CRLF
		cHtml += '     <td>'+ALLTRIM(cProdut)+'</td>'		+ CRLF
		cHtml += '     <td>'+ALLTRIM(cDescr)+'</td>'		+ CRLF
		cHtml += '     <td>'+ALLTRIM(cUnMed)+'</td>'		+ CRLF
		cHtml += '     <td>'+U_picVal(cValToChar(nQuant),"")+'</td>'		+ CRLF
		cHtml += '     <td>'+U_picVal(cValToChar(cVlrUn),cMoeda)+'</td>'		+ CRLF
		cHtml += '     <td>'+U_picVal(cValToChar(nVlrTotal),cMoeda)+'</td>'		+ CRLF
		cHtml += '     <td>'+ALLTRIM(cCC)+'</td>'			+ CRLF
		cHtml += '   </tr>'									+ CRLF
		
		cFlaLine := "0"
		
	EndIf
	SC7->(dbSkip())
EndDo

cHtml+= ' </table>     

_cTotImp:=U_picVal(cValToChar(_cTotImp),cMoeda)

RestArea(xArea)

Return(cHtml)
