#include "protheus.ch"
#include "parmtype.ch"
#INCLUDE "RWMAKE.CH"   
#INCLUDE "APWIZARD.CH" 
#INCLUDE "TOPCONN.CH"
/*
______________________________________________________________________________
|_____________________________________________________________________________|
|Programa  - MT120FIM    Autor  Fabricio Antunes      Data   01/11/2019 	  |
|_____________________________________________________________________________|
|Descricao|Funcao para liberacao de solicitacao de compras                    |
|         |                                                                   |
|_________|___________________________________________________________________|
|Uso      |                                                                   | 
|_________|___________________________________________________________________|
|_____________________________________________________________________________|
*/
User Function MT120FIM()


Local cusername := Alltrim(SuperGetMV("CR_FLUSR",.F.,"usario"))      	 // USUARIO INTEGRADOR       		
Local cpassword := Alltrim(SuperGetMV("CR_FLPSW",.F.,"senha")) 	 //SENHA USUARIO INTEGRADOR 		
Local cURL		:= Alltrim(SuperGetMV("CR_FLURL",.F.,"https://seufluig.fluig.com"))  //URL Fluig
Local lExecut 	:= SuperGetMV("CR_FLUIG",.F.,.F.)      			 		// Habilita integracao Fluig
Local ncompanyId := Alltrim(SuperGetMV("CR_FLCOM",.F.,'1')) 			//CODIGO COMPANIA
Local cprocessId := Alltrim(SuperGetMV("CR_FLPRO",.F.,"000001"))        //Codigo do processo				
Local nchoosedState	:=  '2'			//Stado de inicializacao do processo no Fuig
Local nOpcao 	:= PARAMIXB[1]      // Opcao Escolhida pelo usuario: 1 = Pesquisar; 2 = Visualizar; 3 = Incluir; 4 = Alterar; 5 = Excluir; 9 = Copia
Local nOpcA     := PARAMIXB[3]  	// Indica se a tela foi Cancelada = 0  ou Confirmada = 1.CODIGO DE APLICACAO DO USUARIO.....
Local cComments	:= "Integracao via Protheus - realizada em: "+dtoc(DATE())+" "
Local oWsdl
Local xRet
Local aComplex 	:= {}
Local aSimple := {}
Local nPos := 0, nOccurs := 0
Local aValues:={} 
Local aUser:={}
Local aEnvia:={}
Local cPedaco
Local cPosIni
Local cID
Local aDel:={}
Local cDel
Local nX
Local lErro:=.F.
Local cMsErro:=""
Local cNUser:=""

Private _cSolici := SC7->C7_NUM 
Private _cFillx	 := SC7->C7_FILIAL
Private _cEmissa := SC7->C7_EMISSAO
Private _cFornec := SC7->C7_FORNECE
Private _cTipo	 := SCR->CR_TIPO
Private _cCondPa := Alltrim(SC7->C7_COND) + " - "+Alltrim(Posicione("SE4",1,xFilial("SE4")+Alltrim(SC7->C7_COND),"E4_DESCRI"))
Private _cForNom := Posicione("SA2",1,xFilial("SA2") + SC7->C7_FORNECE + SC7->C7_LOJA,"A2_NREDUZ") 
Private _cTotImp := 0
Private _cItmSl
Private _cUser	:= SC7->C7_USER
Private cMoeda	

IF SC7->C7_MOEDA = 1
	cMoeda:="R$"
ElseIF SC7->C7_MOEDA = 2
	cMoeda:="US$"
else
	cMoeda:="$"	
EndIF

_cItmSl := GeraHTML()

If lExecut
	IF (nOpcao = 4 .OR. nOpcao = 5) .AND. nOpcA = 1 //Em caso de alteracao ou exclusao
		cQuery:=" SELECT CR_XIDFLU, R_E_C_N_O_ AS REC FROM "+RetSqlName("SCR")+" WHERE CR_XIDFLU <> '' AND D_E_L_E_T_ = '*' AND CR_NUM = '"+_cSolici+"' AND CR_DATALIB = ''"
		TcQuery ChangeQuery(cQuery) New Alias "SCRD" 
		cDel:="("
		While !SCRD->(EOF())
			aadd(aDel,{SCRD->CR_XIDFLU, SCRD->REC})
			cDel+=Alltrim(Str(SCRD->REC))+','
			SCRD->(dbSkip())	
		EndDo
		SCRD->(dbCloseArea())
		For nX:=1 to Len(aDel)
			//Chama funcao para cancelar a solicitacao Fluig
			U_M120FM01(aDel[nX,1]) 
		Next

		IF Len(aDel) > 0
			cDel:=SubStr(cDel,1,Len(cDel)-1)+')'
			cQuery:=" UPDATE "+RetSqlName("SCR")+" SET CR_XIDFLU = '' WHERE R_E_C_N_O_ IN "+cDel
			If TcCanOpen(RetSqlName("SCR"))
				if (TCSQLExec(cQuery) < 0)
					 Alert("Erro no TCSQLError() de atualizacao dos registros deletados da SCR para o FLuig favor informar ao suporte a seguinte mensagem: "+ TCSQLError())
				Endif	
			EndIf
		EndIF
	EndIF
	If nOpcA = 1 .AND. (nOpcao = 4 .OR. nOpcao = 9 .OR. nOpcao = 3 ) //Em caso de inclusao, alteracao e capia 
		dbSelectArea("SCR")
		SCR->(dbSetOrder(1))
		IF SCR->(dbSeek(xFilial("SCR")+_cTipo+_cSolici))
		
	
			While !SCR->(EOF()) .AND. SCR->CR_FILIAL+_cTipo+SCR->CR_NUM = xFilial("SCR")+_cTipo+_cSolici
				IF SCR->CR_STATUS = '02'
					aadd(aUser,{SCR->CR_USER, SCR->CR_NIVEL, Recno(), SCR->CR_GRUPO})
				EndIF
				SCR->(dbSkip())
			EndDo
			IF Len(aUser) > 0
			
				ASORT(aUser, , , { | x,y | x[2] < y[2] } )

				For nX:=1 to Len(aUser)
				   IF nX = 1
				   		aaDD(aEnvia,aUser[1])
				   else
						IF aEnvia[1,2] = aUser[nX,2]   
							aaDD(aEnvia,aUser[nX])
						EndIF
				   EndIF
				Next

				For nX:=1 to Len(aEnvia)
					lRet:=.T.
					cUser:=Alltrim(aEnvia[nX,1])
					nRec:=aEnvia[nX,3]
					cNUser+=UsrFullName(Alltrim(aEnvia[nX,1]))+" ,"
					
					//oWs := WSECMWorkflowEngineServiceService():New()
					oWsdl := TWsdlManager():New()
					oWSDL:nTimeout      := 1000 // TEMPO DE ESPERA PARA RESPOSTA
					oWSDL:lVerbose      := .T.  // HABILITA O REGISTRO DOS COMANDOS ENVIADOS E RECEBIDOS
					oWSDL:lSSLInsecure  := .T.  // REALIZA A CONEXaO SSL DE FORMA ANaNIMA
					oWsdl:lRemEmptyTags := .T.  // REMOVE TAGS VAZIAS
					
				
					xRet := oWsdl:ParseURL( cURL+"/webdesk/ECMWorkflowEngineService?wsdl" )
						if xRet == .F.
						cErro:=oWsdl:cError 
						MsgInfo("Erro na integracao com o Fluig favor contactar suporte e informar o seguinte mensagem: "+cErro)
						Return
					endif
					
					xRet := oWsdl:SetOperation( "startProcess" )
					if xRet == .F.
						cErro:=oWsdl:cError 
						MsgInfo("Erro na integracao com o Fluig favor contactar suporte e informar o seguinte mensagem: "+cErro)
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
							MsgInfo("Erro na integracao com o Fluig favor contactar suporte e informar o seguinte mensagem: "+cErro)
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
			
					oWsdl:lProcResp := .F. //Nao processa o retorno automaticamente no objeto (sera tratado atravas do matodo GetSoapResponse)
					lRet := oWsdl:SendSoapMsg(cMessege)
					cError:=oWsdl:cError
					/*cFaultCode:=oWsdl:cFaultCode
					cFaultSubCode:=oWsdl:cFaultSubCode
					cFaultString:=oWsdl:cFaultString
					cFaultActor:=oWsdl:cFaultActor*/
					
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
							Else
								lErro:=.T.
								cMsErro+=cError+"	/	"+cXmlRet
							EndIf
						Else
							lErro:=.T.
							cMsErro+=cError+"	/	"+cXmlRet
						Endif
					Else
						lErro:=.T.
						cMsErro+=cError+"	/	"
					Endif
				Next nX
				//Verica se houve erro para apresentra mensagens
				IF !lErro
					cNUser:=SubStr(cNUser,1,Len(cNUser)-1)
					MsgInfo("Integracao com o fluig para aprovacao de pedido de compras efetuado com sucesso para os seguintes aprovadores: "+cNUser)
				else
					xMagHelpFis("Erro integracao Fluig","Erro na integracao com o Fluig favor contactar suporte e informar o seguinte erro abaixo:",cMsErro)
				EndIF

			Endif
		EndIF
	EndIF
EndIf

Return
/*
#############################################################################
||-------------------------------------------------------------------------||
||aPrograma  |GeraHTML  |Fabricio Antunes            | Data a  22/05/19    ||
||-------------------------------------------------------------------------||
||Desc.      | Funcao estatica para gercao de codigo html para itens do    ||
||           | pedido de compras                                           ||
||-------------------------------------------------------------------------||
||aUso       |                                                             ||
||-------------------------------------------------------------------------||
#############################################################################
*/
Static Function GeraHTML()

Local cFlaLine		:= "0"
Local cColorLi		:= " "
Local nI
Local cItem 
Local cProdut
Local nQuant
Local cDescr
Local cUnMed
Local nVlrTotal

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

for nI:= 1 to Len(ACOLS)
	
	cItem 		:=	ACOLS[nI][ aScan(aHeader,{|x|AllTrim(x[2])=="C7_ITEM"})] 
	cProdut		:=	ACOLS[nI][ aScan(aHeader,{|x|AllTrim(x[2])=="C7_PRODUTO"})]
	nQuant		:=	ACOLS[nI][ aScan(aHeader,{|x|AllTrim(x[2])=="C7_QUANT"})]
	cDescr		:=	ACOLS[nI][ aScan(aHeader,{|x|AllTrim(x[2])=="C7_DESCRI"})]
	cVlrUn		:=  ACOLS[nI][ aScan(aHeader,{|x|AllTrim(x[2])=="C7_PRECO"})]
	cUnMed		:=	ACOLS[nI][ aScan(aHeader,{|x|AllTrim(x[2])=="C7_UM"})]
	nDesc		:=  ACOLS[nI][ aScan(aHeader,{|x|AllTrim(x[2])=="C7_VLDESC"})]
	nVlrTotal	:=	ACOLS[nI][ aScan(aHeader,{|x|AllTrim(x[2])=="C7_TOTAL"})]
	cCC			:= 	ACOLS[nI][ aScan(aHeader,{|x|AllTrim(x[2])=="C7_CC"})]
	cCC			:= 	Posicione("CTT",1,xFilial("CTT")+cCC,"CTT_DESC01")


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
next

cHtml+= ' </table>       

_cTotImp:=U_picVal(cValToChar(_cTotImp),cMoeda)

Return(cHtml)

/*
#############################################################################
||-------------------------------------------------------------------------||
||aPrograma  |GeraHTML  |Fabricio Antunes            | Data a  22/05/19    ||
||-------------------------------------------------------------------------||
||Desc.      | Funcao estatica para gercao de codigo html para itens do    ||
||           | pedido de compras                                           ||
||-------------------------------------------------------------------------||
||aUso       |                                                             ||
||-------------------------------------------------------------------------||
#############################################################################
*/

User Function M120FM01(cId)

Local cusername := Alltrim(SuperGetMV("CR_FLUSR",.F.,"user"))      	 // USUARIO INTEGRADOR       		
Local cpassword := Alltrim(SuperGetMV("CR_FLPSW",.F.,"senha")) 	 //SENHA USUARIO INTEGRADOR 		
Local cURL		:= Alltrim(SuperGetMV("CR_FLURL",.F.,"https://seufluig.fluig.com"))  //URL Fluig
Local ncompanyId := Alltrim(SuperGetMV("CR_FLCOM",.F.,'1')) 			//CODIGO COMPANIA
Local lRet



	oWsdl := TWsdlManager():New()
	oWSDL:nTimeout      := 1000 // TEMPO DE ESPERA PARA RESPOSTA
	oWSDL:lVerbose      := .T.  // HABILITA O REGISTRO DOS COMANDOS ENVIADOS E RECEBIDOS
	oWSDL:lSSLInsecure  := .T.  // REALIZA A CONEXaO SSL DE FORMA ANaNIMA
	oWsdl:lRemEmptyTags := .T.  // REMOVE TAGS VAZIAS
	

	xRet := oWsdl:ParseURL( cURL+"/webdesk/ECMWorkflowEngineService?wsdl" )
	if xRet == .F.
		cErro:=oWsdl:cError 
		Return
	endif
	
	xRet := oWsdl:SetOperation( "cancelInstance" )
	if xRet == .F.
		cErro:=oWsdl:cError 
		Return
	endif

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
	nPos := aScan( aSimple, {|aVet| aVet[2] == "processInstanceId" .AND. aVet[5] == "processInstanceId" } )
	IF nPos > 0
		xRet := oWsdl:SetValue( aSimple[nPos][1], Alltrim(cID) ) 	
	EndIF
	
	nPos:=0
	nPos := aScan( aSimple, {|aVet| aVet[2] == "userId" .AND. aVet[5] == "userId" } )
	IF nPos > 0
		xRet := oWsdl:SetValue( aSimple[nPos][1], cusername ) 	
	EndIF
	
	nPos:=0
	nPos := aScan( aSimple, {|aVet| aVet[2] == "cancelText" .AND. aVet[5] == "cancelText" } )
	IF nPos > 0
		xRet := oWsdl:SetValue( aSimple[nPos][1], "Tarefa movimentada pelo Protheus" ) 	
	EndIF

	cMessege:=oWsdl:GetSoapMsg()
				
	//Retirado o elemento da tag devido o obj nao suportar
	cMessege := StrTran(cMessege, ' xmlns="http://ws.dm.ecm.technology.totvs.com/"', '')
	cMessege := StrTran(cMessege, "<?xml version='1.0' encoding='UTF-8' standalone='no' ?>", '')

	cMessege:=EncodeUTF8(cMessege)

	oWsdl:lProcResp := .F. //Nao processa o retorno automaticamente no objeto (sera tratado atravas do matodo GetSoapResponse)
	lRet := oWsdl:SendSoapMsg(cMessege)
	cError:=oWsdl:cError
	
	If lRet
		//Trata a resposta do WebService
		cXmlRet := oWsdl:GetSoapResponse()
		If ! Empty( cXmlRet )
		
			cPosIni:= At("<result>",cXmlRet)
			IF cPosIni > 0
				cPosIni+=8
				cResult:= SubStr(cXmlRet,cPosIni,2)
				IF !cResult = 'OK'
					MsgInfo("Erro no cancelamento do processo no Fluig de id: "+Alltrim(cID)+". favor contactar suporte e informar o seguinte erro: "+cError)
				EndIf
			EndIf
		Else
			MsgInfo("Erro no cancelamento do processo no Fluig de id: "+Alltrim(cID)+". favor contactar suporte e informar o seguinte erro: "+cError)
		Endif
	Else
		MsgInfo("Erro no cancelamento do processo no Fluig de id: "+Alltrim(cID)+". favor contactar suporte e informar o seguinte erro: "+cError)
	Endif

Return



/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณpicVal    บAutor  ณFabricio Antunes    บ Data ณ  10/12/19   บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ Funcao para retornar a picture correta de valores em       บฑฑ
ฑฑบ          ณ moeda (tratado como texto)                                 บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ AP                                                         บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

User Function picVal (cValor,cMoeda)
Local nTamanho:=Len(cValor) //13
Local nPosP:=At(".",cValor) //12
Local aPart:={}
Local cRet:=''
Local nx, nQuant
Default cMoeda := ""

If nTamanho - nPosP = 1
	cValor:=cValor+"0"
EndIF

IF nTamanho - nPosP = 0
	cValor:=cValor+"00"
EndIF

IF nPosP = 0
	cValor:=cValor+".00"
EndIF

cValor:=Strtran(cValor,'.',",")
cInt:=SubStr(cValor,1,Len(cValor)-3)
cDec:=SubStr(cValor,Len(cValor)-2,3)
nQuant:=Int(Len(cInt)/3)

For nx:=1 to nQuant
	AADD(aPart,SubStr(cInt,Len(cInt)-2,3))
	cInt:=SubStr(cInt,1,Len(cInt)-3)
Next

AADD(aPart,cInt)

For nx:=Len(aPart) to 1 step -1
	IF Alltrim(aPart[nx]) <> ''
		cRet+=aPart[nx]+'.'
	EndIF
Next
cRet:=cMoeda+SubStr(cRet,1,Len(cRet)-1)+cDec
Return (cRet)

User Function ValPic
Local cValor :="90000000.0"
Local cMoeda :="U$"
Local cRet:= ""

cRet:=U_picVal(cValor,cMoeda)

cRet:=cRet

Return
