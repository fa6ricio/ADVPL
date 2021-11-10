#INCLUDE "PROTHEUS.CH"
#INCLUDE "rwmake.ch"
#INCLUDE "TopConn.Ch"
#INCLUDE "TBICONN.CH"
#INCLUDE "TBICODE.CH"
#INCLUDE "APWEBSRV.CH"

/*
______________________________________________________________________________
|_____________________________________________________________________________|
|Programa  - FATW001    Autor  Fabricio Antunes      Data   07/04/2016   	  |
|_____________________________________________________________________________|
|Descricao|WebService WSDL para geracao de pedido de vendas                   |
|         |                                                                   |
|_________|___________________________________________________________________|
|Uso      |                                                                   | 
|_________|___________________________________________________________________|
|_____________________________________________________________________________|
*/


WsStruct PEDITENS
 	WsData C6_PRODUTO 	As String
	WsData C6_QTDVEN 	As FLOAT
	WsData C6_PRCVEN 	As FLOAT  
	WsData C6_TES  		As STRING 	OPTIONAL    
EndWsStruct                       

WsStruct PEDIDOS
    //Cabec do Pedido     
    WsData C5_NUM  		As STRING  
    WsData C5_ZNUMSIS 	As INTEGER  
    WsData C5_TIPO 		As STRING  
    WsData C5_CLIENTE 	As STRING  
    WsData C5_CONDPAG 	As STRING  
    WsData C5_TIPOCLI 	As STRING  
    WsData C5_EMISSAO 	As STRING
    WsData C5_ZFRTCIF 	As FLOAT 	OPTIONAL 
    WsData C5_ZIMPORT 	As FLOAT 	OPTIONAL  
    WsData C5_ZPFUND 	As FLOAT 	OPTIONAL  
    WsData C5_ZVFUND 	As FLOAT 	OPTIONAL  
    WsData C5_ZLOTE 	As STRING 	OPTIONAL  
    WsData C5_ZNAVIO 	As STRING 	OPTIONAL  
    WsData C5_ZQTDPER 	As INTEGER 	OPTIONAL  
    WsData C5_ZPERINC 	As STRING 	OPTIONAL  
    WsData C5_ZPERFIN 	As STRING 	OPTIONAL  
    WsData C5_ZCONHE 	As STRING 	OPTIONAL  
    WsData C5_ZCOMIS 	As STRING 	OPTIONAL  
	WsData oItens	   as ARRAY OF  PEDITENS 		
		
EndWsStruct

WsStruct RETIMPPED
 	WsData oItensRet    as ARRAY OF  PEDITENS OPTIONAL 
 	WsData lStatus      AS Boolean
 	WSData cMensgem 	As String	     
 	WSDATA ALIQISS		AS FLOAT	OPTIONAL
 	WSDATA ALIQPIS		As FLOAT	OPTIONAL
 	WSDATA ALIQCOF		As FLOAT	OPTIONAL
 	WSDATA VALISS		as FLOAT	OPTIONAL
 	WSDATA VALPIS		as FLOAT	OPTIONAL
 	WSDATA VALCOF		as FLOAT	OPTIONAL
 	WSDATA VENCTO		as DATE		OPTIONAL   
 	WSDATA NUMPROTH		as STRING	OPTIONAL
EndWsStruct

WsService IMPPEDIDOS DESCRIPTION "WebService de integração Protheus para importação do pedido de venda"

    WsData cUser		As String 
    WsData cPassword 	As STRING 
    WsData oPedidos     As PEDIDOS
	WSData cWSRETURN   As RETIMPPED

    WsMethod GERAPEDIDO DESCRIPTION "Metodo para faturamento do pedido de compra do Supporte  via MSExecAuto() da MATA410"

EndWsService


/*
______________________________________________________________________________
|_____________________________________________________________________________|
|Programa  - GERAPEDIDO    Autor  Fabricio Antunes      Data   07/04/2016 	  |
|_____________________________________________________________________________|
|Descricao|Metodo para geracao de pedido de vendas                            |
|         |                                                                   |
|_________|___________________________________________________________________|
|Uso      |                                                                   | 
|_________|___________________________________________________________________|
|_____________________________________________________________________________|
*/


WsMethod GERAPEDIDO WsReceive cUser,cPassword,oPedidos WsSend cWSRETURN WsService IMPPEDIDOS


Local cChave 	:= ::cPassword  //CHAVE DE VALIDAO ORIGEM
Local cUser 	:= ::cUser
Local aCabec	:={}
Local aItens	:={} 
Local nX                                                              
Local lRet		:=.T.
Private aImp	:={}
Private cNumSis	:=Alltrim(Str(oPedidos:C5_ZNUMSIS))
Private cXML	:=HttpOtherContent() //Salva XML recebido
Private aCond	:={}
conOut("[PROCESSAMENTO] GERAPEDIDO " + dtoc(date()) + " " + Time() +"==>Inicio do processamento!")
_cUser:= 'protheus'
_cPsw := MD5('pr!th3vz',2)

//Abre tabela de log de operacoes
dbSelectArea("SZ1")
SZ1->(dbSetOrder(1))

IF AllTrim(_cUser) == AllTrim(cUser) .and. AllTrim(cChave) == AllTrim(_cPsw)    
        
        //grava log de inicio de processamento    
        IF !U_LogSispl('1','INCLUSAO PEDIDO',cNumSis,,"INICIO PROCESSAMENTO WEBSERVICE",cXML)
        	conOut("[ERRO] GERAPEDIDO " + dtoc(date()) + " " + Time() +"==>Erro na gravaçoca do logo SZ1!")
		EndIF                
        
        cQuery:=" SELECT R_E_C_N_O_ AS REC FROM "+RetSqlName("SA1")
        cQuery+=" WHERE A1_MSBLQL <> '1' AND D_E_L_E_T_ = '' AND A1_CGC = '"+Alltrim(oPedidos:C5_CLIENTE)+"'"
		TcQuery ChangeQuery(cQuery) New Alias "CLIE"
		
		IF !CLIE->(EOF())
			dbSelectArea("SA1")
			SA1->(dbGoTo(CLIE->REC))
		
	         conOut("[PROCESSAMENTO] GERAPEDIDO " + dtoc(date()) + " " + Time() +"==>Gerando cabecalho do pedido!")
	         AADD(aCabec,{'C5_ZNUMSIS'	 , oPedidos:C5_ZNUMSIS	,NIL})
	         AADD(aCabec,{'C5_TIPO'   	 , oPedidos:C5_TIPO		,NIL})
	         AADD(aCabec,{'C5_CLIENTE'	 , SA1->A1_COD			,NIL})
	         AADD(aCabec,{'C5_LOJACLI'	 , SA1->A1_LOJA			,NIL})
	         AADD(aCabec,{'C5_CONDPAG'	 , SA1->A1_COND			,NIL})  
	         AADD(aCabec,{'C5_TIPOCLI'	 , oPedidos:C5_TIPOCLI	,NIL})  
	         cData:=dTos(cTod(oPedidos:C5_EMISSAO))
	         cData:=SubStr(cData,1,4)+SubStr(cData,7,2)+SubStr(cData,5,2)
	         dData:=dDataBase
	         AADD(aCabec,{'C5_EMISSAO' 	 , dData	,NIL})   
	         aCond:=Condicao(100,SA1->A1_COND,,dData)
         
	         AADD(aCabec,{'C5_NATUREZ'	 , '18002'		,NIL})
	         
	         conOut("[PROCESSAMENTO] GERAPEDIDO " + dtoc(date()) + " " + Time() +"==>Gerando Itens do Pedido!")
	         For nX:=1 to Len(oPedidos:oItens)
	        	aadd(aItens,{oPedidos:oItens[nX]:C6_PRODUTO,oPedidos:oItens[nX]:C6_PRCVEN,oPedidos:oItens[nX]:C6_QTDVEN, oPedidos:oItens[nX]:C6_TES})
	         Next 
	         
	         conOut("[PROCESSAMENTO] GERAPEDIDO " + dtoc(date()) + " " + Time() +"==>Chamada do Execauto!")
	         aRet	:= U_FATW001P(aCabec,aItens)
	         
	         conOut("[PROCESSAMENTO] GERAPEDIDO " + dtoc(date()) + " " + Time() +"==>Inicio montagem do retorno!")
	         For nX:=1 to Len(aImp)  
	         	
	         	conOut("[PROCESSAMENTO] GERAPEDIDO " + dtoc(date()) + " " + Time() +"==>Montando itens do produto do retorno!")
	        	oProdut:= WsClassNew("PEDITENS") 
		        	oProdut:C6_PRODUTO	:=aImp[nX][1]
		        	oProdut:C6_QTDVEN	:=aImp[nX][2]
		        	oProdut:C6_PRCVEN	:=aImp[nX][3]
		        	oProdut:C6_TES		:=aImp[nX][4]
		        AADD(cWSRETURN:oItensRet,oProdut)
	         Next
	         conOut("[PROCESSAMENTO] GERAPEDIDO " + dtoc(date()) + " " + Time() +"==>Montando outro atributos de retorno!")
	         ::cWSRETURN:cMensgem	:= aRet[1]  
	         ::cWSRETURN:lStatus	:= aRet[2]    
			 ::cWSRETURN:ALIQISS	:= aRet[3] 
			 ::cWSRETURN:ALIQPIS	:= aRet[4] 
			 ::cWSRETURN:ALIQCOF	:= aRet[5] 
			 ::cWSRETURN:VALISS		:= aRet[8] 
			 ::cWSRETURN:VALPIS		:= aRet[6] 
			 ::cWSRETURN:VALCOF		:= aRet[7] 
			 ::cWSRETURN:VENCTO		:= aCond[1][1]
			 ::cWSRETURN:NUMPROTH	:= aRet[10]
	         lRet:=aRet[2]
	         
	         //cRet,!lMsErroAuto,pPISS,pPPIS,pPCOF,nTotPis,nTotCof,nTotISS,dDataBase
	 	Else 
	 		//grava log de inicio de processamento    
		    IF !U_LogSispl('2','INCLUSAO PEDIDO',cNumSis,,"CLIENTE NAO ENCONTRADO - CNPJ: "+Alltrim(oPedidos:C5_CLIENTE),cXML)
		      	conOut("[ERRO] GERAPEDIDO " + dtoc(date()) + " " + Time() +"==>Erro na gravaçoca do logo SZ1!")
			EndIF   
			
	 		conOut("[ERRO] GERAPEDIDO " + dtoc(date()) + " " + Time() +"==>Cliente nao encontrado!")
   			::cWSRETURN:cMensgem 	:= "0;0000 -CLIENTE NAO ENCONTRADO" //RETORNO DE OPERAO NO CONCLUIDA
   			::cWSRETURN:lStatus	:=.F.  
   			lRet:=.F.
	 	EndIF
	 	CLIE->(dbCloseArea())
Else
	conOut("[ERRO] GERAPEDIDO " + dtoc(date()) + " " + Time() +"==>Chave de segurança inválida!")      
   
	//grava log de inicio de processamento    
    IF !U_LogSispl('2','INCLUSAO PEDIDO',cNumSis,,"SENHA INVALIDA",cXML)
        	conOut("[ERRO] GERAPEDIDO " + dtoc(date()) + " " + Time() +"==>Erro na gravaçoca do logo SZ1!")
	EndIF  
	
	::cWSRETURN:cMensgem := "0;0000 -CHAVE DE SEGURANCA INVÁLIDA" //RETORNO DE OPERAO NO CONCLUIDA   
	::cWSRETURN:lStatus	:=.F. 
	lRet:=.F.
EndIf

Return(lRet)     

/*
______________________________________________________________________________
|_____________________________________________________________________________|
|Programa  - FATW001P    Autor  Fabricio Antunes      Data   07/04/2016 	  |
|_____________________________________________________________________________|
|Descricao|Funcao de validacao e execucao de execauto para inclusao do pedido |
|         |                                                                   |
|_________|___________________________________________________________________|
|Uso      |                                                                   | 
|_________|___________________________________________________________________|
|_____________________________________________________________________________|
*/

User Function FATW001P(aCabec,aItens)

Local aLinha:={}
Local aSC6:={}
Local aRet:={}
Local cTES:="501"
Local nX  
Local nISS
Local nPIS
Local nConf
Local nValor   
Local cGerImp :=SA1->A1_S_IMPPR
Local pPISS	  :=IF(cGerImp = '1',SA1->A1_S_ISS,0)
Local pPPIS	  :=IF(cGerImp = '1',SA1->A1_S_PIS,0 )
Local pPCOF	  :=IF(cGerImp = '1',SA1->A1_S_CONFI,0)  
Local nTotPis:=nTotCof:=nTotISS:=0
Local cNumPed:="" 

Private lMsErroAuto :=.F.
Private lAutoErrNoFile:=.T.  


//Regra de preenchimento de TES / Cliente Pronta Entrega
dbSelectArea("SA1")
SA1->(dbSetOrder(1))

	aCabec := FWVetByDic(aCabec, 'SC5')    //cData:=SubStr(aCabec[18][1],1,10)
	
	
	dbSelectArea("SB1")
	SB1->(dbSetOrder(1))
		For nX:= 1 to Len(aItens)  
			conOut("[PROCESSAMENTO] GERAPEDIDO " + dtoc(date()) + " " + Time() +"==>Selecionando serviço/produto no Protheus!")
			IF SB1->(dbSeek(xFilial("SB1")+aItens[nX][1]))
				    

					nISS:=0
					nPIS:=0
					nConf:=0 
					nValor:=aItens[nX][2]
					
					conOut("[PROCESSAMENTO] GERAPEDIDO " + dtoc(date()) + " " + Time() +"==>Calculo de impostos no preço!")
					//Verifica se adicionara o valor de impostos ao preço para o cliente
					IF cGerImp = '1'
						nTotper	:= pPISS+pPPIS+pPCOF
						nValor	:= Round((nValor/(1-(nTotper/100))),2) 
						
						nISS	:=	Round(nValor*pPISS/100,2)
						nPIS	:=	Round(nValor*pPPIS/100,2)
						nConf	:=  Round(nValor*pPCOF/100,2)
					EndIF
					
					nTotPis+=nPIS
					nTotCof+=nConf 
					nTotISS+=nISS
					
					
					conOut("[PROCESSAMENTO] GERAPEDIDO " + dtoc(date()) + " " + Time() +"==>Alimentando array de retorno!")
					AADD(aImp,{aItens[nX][1], aItens[nX][3], nValor, '501'})   
					
					conOut("[PROCESSAMENTO] GERAPEDIDO " + dtoc(date()) + " " + Time() +"==>Montando itens do execauto!")
				   //	AADD(aLinha, {"C6_NUM"		,cNum	   			   						,Nil}  )
					AADD(aLinha, {"C6_ITEM"		,StrZero(nX,2)	   	 						,Nil}  )
					AADD(aLinha, {"C6_PRODUTO"	,SB1->B1_COD	  	  						,Nil}  )
					AADD(aLinha, {"C6_QTDVEN"	,aItens[nX][3]								,Nil}  )
					AADD(aLinha, {"C6_PRCVEN"	,nValor										,Nil}  )
					AADD(aLinha, {"C6_TES"		,cTes				  						,Nil}  )
					AAdd(aSC6,aLinha)
					aLinha:={}  
			EndIF
		Next nX
	    

		lMsErroAuto := .F.
	    
  		conOut("[PROCESSAMENTO] GERAPEDIDO " + dtoc(date()) + " " + Time() +"==>Executando o execauto!")		
   		MSExecAuto({|x,y,z|Mata410(x,y,z)},aCabec,aSC6,3)
	
		If lMsErroAuto
				//RollbackSx8()
				aAutoErro := GetAutoGRLog()
				cRet:="Erro na inclusão do pedido, favor contactar suporte técnico Supporte"   
				conOut("[ERRO] GERAPEDIDO " + dtoc(date()) + " " + Time() +"==>Erro na execução do execauto!")
				cErroAt:=""
				For nX:=1 to Len(aAutoErro)
				   cErroAt+=aAutoErro[nX]+ Chr(13) + Chr(10)
				Next
		Else 

				cRet:="Pedido de numero "+SC5->C5_NUM+" incluido com sucesso!" 
				conOut("[PROCESSAMENTO] GERAPEDIDO " + dtoc(date()) + " " + Time() +"==>Execauto processado com sucesso!") 
				cNumPed:=SC5->C5_NUM
		EndIf
	    
	    aRet:={cRet,!lMsErroAuto,pPISS,pPPIS,pPCOF,nTotPis,nTotCof,nTotISS,dDataBase,cNumPed}


Return aRet       



/*
______________________________________________________________________________
|_____________________________________________________________________________|
|Programa  - MtXmlWs    Autor  Fabricio Antunes      Data   07/04/2016 	      |
|_____________________________________________________________________________|
|Descricao| Monta XML da estrutura                                            |
|         |                                                                   |
|_________|___________________________________________________________________|
|Uso      |                                                                   | 
|_________|___________________________________________________________________|
|_____________________________________________________________________________|
*/
User Function MtXmlWs(oObj,cNodPai)

Local aAtribut		:= {}		// Array com os atributos do objeto
Local cRet	  		:= ""		// Variavel de retorno
Local cNmAtrb		:= ""		// Nome do atributo
Local nFor	  		:= 0		// Contador do For
Local nForIt		:= 0		// Contador do For interno
                	
Default cNodPai		:= ""

//-------------------------------------
//-Retorna as propriedades do objeto. -
//-------------------------------------
aAtribut := ClassDataArr(oObj)

cRet := "<" + cNodPai + ">"

//------------------------------------
//-Monta String XML com base no array-
//------------------------------------
For nFor := 1 to Len(aAtribut)

	cNmAtrb := aAtribut[nFor][1]
	
		//-----------------------------------------
		//-Se o conteudo for obj. chama recursivo -
		//-----------------------------------------
		If (ValType(aAtribut[nFor][2]) == "O")
			
			cRet +=	U_MtXmlWs(aAtribut[nFor][2],cNmAtrb)
		
		ElseIf (ValType(aAtribut[nFor][2]) == "A")
			
			//------------------------------------------------------------
			//-Se o conteudo for array chama recursivo para cada posicao -
			//------------------------------------------------------------
			For nForIt := 1 to Len(aAtribut[nFor][2])
				cRet += U_MtXmlWs(aAtribut[nFor][2][nForIt],cNmAtrb)
			Next nForIt
			
		Else

			//-------------------------------
			//-Adiciona conteudo do tributo -
			//-------------------------------
			cRet += "<" + cNmAtrb + ">"
			
			If (ValType(aAtribut[nFor][2]) <> "U")
				cRet += CValToChar(aAtribut[nFor][2])
			EndIf
			
			cRet += "</" + cNmAtrb + ">"
	
		EndIf	

Next nFor 

cRet += "</" + cNodPai + ">"

Return cRet
