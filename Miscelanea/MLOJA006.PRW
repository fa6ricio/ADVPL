#include "protheus.ch"
#include "topconn.ch"
#include "autodef.ch"


/*
______________________________________________________________________________
|_____________________________________________________________________________|
|Programa  - MLOJA006    Autor  Fabricio Antunes      Data   26/05/2021   	  |
|_____________________________________________________________________________|
|Descricao|Funcao para comunicacao de desconto do portal de drogaria          |
|         |                                                                   |
|_________|___________________________________________________________________|
|Uso      | Coopervap                                                         | 
|_________|___________________________________________________________________|
|_____________________________________________________________________________|
*/


User Function MLOJA006
Local lRet:=.F.
Local cDt :=dTos(dDataBase)
Local cTime :=StrTran(Time(),':','')
Local cOrc  :=M->LQ_NUM

Public _cArqTxt  := cOrc+"_"+cDt+"_"+cTime+".001"
Public _cArqTxRT := "RET_"+cOrc+"_"+cDt+"_"+cTime+".001"
Public _cArqTxFN := "FN_"+cOrc+"_"+cDt+"_"+cTime+".001"
Public nHdl
Public cEOL      := "CHR(13)+CHR(10)"
Public cDirSrv   := "\TRNCENTR\"
Public cDirArq   := "C:\TRNCENTR\REQ\"
Public cDirRet   := "C:\TRNCENTR\RESP\"

Public _lFarma   := .F.

IF Alltrim(M->LQ_NSU) = ""
    MsgAlert("Para usar o desnconto do portal de drogarias favor preencher o NSU!")
    Return
EndIF

IF Alltrim(M->LQ_OPFAR) = ""
    MsgAlert("Para usar o desnconto do portal de drogarias favor preencher Operadora!")
    Return
EndIF

Processa({|| lRet:=MLOJA06A() },"Gerando Arquivo de integacao...")
IF lRet 
    Processa({|| lRet:=MLOJA06B() },"Aguardando e processando arquivo de retorno...")
    IF lRet
        MsgInfo("Integracao realizada com sucesso!")
    EndIF
EndIF



Return

/*
______________________________________________________________________________
|_____________________________________________________________________________|
|Programa  - MLOJA006    Autor  Fabricio Antunes      Data   26/05/2021   	  |
|_____________________________________________________________________________|
|Descricao|Funcao para geracao do arquivo de integracao do portal da drogaria |
|         |                                                                   |
|_________|___________________________________________________________________|
|Uso      | Coopervap                                                         | 
|_________|___________________________________________________________________|
|_____________________________________________________________________________|
*/

Static Function MLOJA06A
Local lRet:=.F.

If !ExistDir(cDirSrv)     
    MakeDir(cDirSrv)
EndIF

nHdl := fCreate(cDirSrv+_cArqTxt )
            
If nHdl == -1
		MsgAlert("O arquivo de nome "+_cArqTxt +" nao pode ser criado, favor verficar a instalacao da integracao","Atencao!")
		Return
Endif
	
If Empty(cEOL)
    cEOL := CHR(13)+CHR(10)
Else
    cEOL := Trim(cEOL)
    cEOL := &cEOL
Endif


cLin := "000-000 = 0100" + cEOL
cLin += "011-000 = 800500" + cEOL
cLin += "001-000 = "+Alltrim(M->LQ_NUM) + cEOL
cLin += "040-000 = "+Alltrim(M->LQ_OPFAR) + cEOL
cLin += "012-000 = "+Alltrim(M->LQ_NSU) + cEOL
cLin += "940-000 = 003" + cEOL
cLin += "942-000 = 23153943002012" + cEOL //Alterar para filial da farmácia - 23153943002012 //23.153.943/0020-12
cLin += "023-000 = "+StrTran(Time(),":","") + cEOL
cLin += "022-000 = "+SubStr(dTos(dDataBase),5,2)+SubStr(dTos(dDataBase),7,2) + cEOL
IF Alltrim(M->LQ_CARPOP) <> ''
    cLin += "953-000 = "+StrTran(Alltrim(M->LQ_CARPOP),'.','') + cEOL
EndIF
cLin += "004-000 = REA" + cEOL
cLin += "900-000 = 0"


If fWrite(nHdl,cLin,Len(cLin)) != Len(cLin)
    MsgAlert("Ocorreu um erro na gravaco do arquivo favor contactar a TI.","Atencao!")
    fClose(nHdl)
    Return lRet
Else
    fClose(nHdl)
    If CpyS2T( cDirSrv+_cArqTxt , cDirArq )
        _lFarma:=.T.
        lRet:=.T.
    Else
        msgAlert('Copia do arquivo do sevidor: "'+cDirSrv+_cArqTxt +'" para a pasta local: "'+cDirArq+_cArqTxt +'" ocorreu erro, favor comunciar a TI, integracao nao sera possivel!',"Atencao")
    EndIF

Endif

Return lRet


/*
______________________________________________________________________________
|_____________________________________________________________________________|
|Programa  - MLOJA00B    Autor  Fabricio Antunes      Data   26/05/2021   	  |
|_____________________________________________________________________________|
|Descricao|Funcao para comunicacao de desconto do portal de drogaria          |
|         |                                                                   |
|_________|___________________________________________________________________|
|Uso      | Coopervap                                                         | 
|_________|___________________________________________________________________|
|_____________________________________________________________________________|
*/

Static Function MLOJA06B

Local aFiles  := {}
Local aDados  := {}
Local lLoop:=.T.
Local nEspera:=5000
Local nX, nY, nH
Local lRet:=.F.
Local aProd:={}
Local nItem:=0
Local aLJ7104       :={}
Local nPosItem		:= aPosCpo[Ascan(aPosCpo,{|x| AllTrim(Upper(x[1])) == "LR_ITEM"})][2]
Local nPosProd		:= aPosCpo[Ascan(aPosCpo,{|x| AllTrim(Upper(x[1])) == "LR_PRODUTO"})][2]
Local nPosVlrI  	:= aPosCpo[Ascan(aPosCpo,{|x| AllTrim(Upper(x[1])) == "LR_VRUNIT"})][2]
Local nPosXTES 	    := aPosCpo[Ascan(aPosCpo,{|x| AllTrim(Upper(x[1])) == "LR_XTES"})][2]
Local nPosQuant	    := aPosCpo[Ascan(aPosCpo,{|x| AllTrim(Upper(x[1])) == "LR_QUANT"})][2]

While lLoop
    Sleep( nEspera )
    aFiles := Directory(cDirRet+"*.001")

    IF Len(aFiles) >= 1
        
        For nX := 1 To Len(aFiles)
            IF Alltrim(aFiles[nX,1]) == _cArqTxt 
                lLoop:=.F.
                FT_FUSE(cDirRet+aFiles[nX,1]) 
                FT_FGOTOP() 	
                aDados:={}					
                While !FT_FEOF()
                    cBuffer := FT_FREADLN() 
                    cBuffer := StrTran(cBuffer," = ","-")
                    aaDD(aDados,StrTokArr( cBuffer, '-' ))
                    FT_FSKIP() 
                EndDo
                FT_FUSE()
                //FErase(cDirRet+aFiles[nX,1])
                nItem:=0
                For nY:=1 to Len(aDados)
                    lRet:=.T.
                    /*Estrutura do aProd
                        1 - Indice
                        2 - Produto
                        3 - Quantidade
                        4 - Preço Bruto
                        5 - Preço Liquido
                        6 - Valor a receber
                        7 - % Desconto*/
                    IF aDados[nY,1] = '902'
                        nItem++
                        aadd(aProd,{nItem,aDados[nY,3],nil,nil,nil,nil,nil})
                    ElseIF aDados[nY,1] = '905'
                        aProd[nItem,3]:= Val(aDados[nY,3])
                    ElseIF aDados[nY,1] = '910'
                        aProd[nItem,4]:= Val(SubStr(aDados[nY,3],1,Len(aDados[nY,3])-2)+'.'+SubStr(aDados[nY,3],Len(aDados[nY,3])-1,2))
                    ElseIF aDados[nY,1] = '911'
                        aProd[nItem,5]:= Val(SubStr(aDados[nY,3],1,Len(aDados[nY,3])-2)+'.'+SubStr(aDados[nY,3],Len(aDados[nY,3])-1,2))
                    ElseIF aDados[nY,1] = '912'
                        aProd[nItem,6]:= Val(SubStr(aDados[nY,3],1,Len(aDados[nY,3])-2)+'.'+SubStr(aDados[nY,3],Len(aDados[nY,3])-1,2))
                    ElseIF aDados[nY,1] = '909'
                        aProd[nItem,7]:= Val(SubStr(aDados[nY,3],1,Len(aDados[nY,3])-2)+'.'+SubStr(aDados[nY,3],Len(aDados[nY,3])-1,2))
                    EndIF
                Next nX
                dbSelectArea("SB1")
                SB1->(dbSetOrder(5))
                
               
                IF Len(aProd) = 0
                    lRet:=.F.
                    msgAlert("A integracao retornou nenhum item elegivel para desconto")
                    Return(lRet)
                EndIF
                
    
                For nX:=1  to Len(aProd)
          
                    IF SB1->(dbSeek(xFilial("SB1")+aProd[nX,2]))
                        For nH:=1 to Len(aCols)
                            IF aCols[nH,nPosProd] = SB1->B1_COD
                                IF aCols[nH,nPosQuant] = aProd[nX,3]
                                    nValdesc:= aCols[nH,nPosVlrI]-aProd[nX,6]
                                    nPercDesc:=Round(nValdesc*100/aCols[nH,nPosVlrI],2)
                                    nValdesc:=nValdesc*aCols[nH,nPosQuant]
                                    aCols[nH,nPosXTES]:='DES'
                                    aaDD(aLJ7104,{aCols[nH,nPosItem],aCols[nH,nPosProd],nValdesc,nPercDesc})
                                    Exit
                                Else
                                     MsgAlert("Quantidade do produto  com codigo de barras: "+aProd[nX,2]+" nao confere com a quantidade autorizada pelo portal!")
                                EndIF
                            EndIF
                        Next nH
                    Else
                        MsgAlert("Produto de codigo de barras: "+aProd[nX,2]+" nao encontrado na base o mesmo nao sera processado!")

                    EndIF   
         
                Next
                                   
                IF Len(aLJ7104) >=1
                    LJ7AplDesc(aLJ7104)
                    nPerDesc := 0
                    nVlrDesc := 0
                    Eval(bRefresh)
                EndIF

                Exit
            EndIF
        Next nX
    EndIF                
 
    IF lLoop
        IF msgYesNo("O sistema ainda nao obteve o retorno da integracao deseja aguardar mais "+Alltrim(Str(nEspera/1000))+" segundos?")
            Sleep( nEspera )
            nEspera+=5000
        Else
            lLoop:=.F.
        EndIF
    EndIF
EndDo


Return lRet


/*
______________________________________________________________________________
|_____________________________________________________________________________|
|Programa  - MLOJA006    Autor  Fabricio Antunes      Data   26/05/2021   	  |
|_____________________________________________________________________________|
|Descricao|Funcao para geracao de confirmacao de transacao portal da drogaria |
|         |                                                                   |
|_________|___________________________________________________________________|
|Uso      | Coopervap                                                         | 
|_________|___________________________________________________________________|
|_____________________________________________________________________________|
*/

User Function MLOJA06D
Local lRet:=.T.
Local nHdl
Local nQuant:=0
Local nX
Local nPosProd		:= aPosCpo[Ascan(aPosCpo,{|x| AllTrim(Upper(x[1])) == "LR_PRODUTO"})][2]
Local nPosVlrI  	:= aPosCpo[Ascan(aPosCpo,{|x| AllTrim(Upper(x[1])) == "LR_VRUNIT"})][2]
Local nPosXTES 	    := aPosCpo[Ascan(aPosCpo,{|x| AllTrim(Upper(x[1])) == "LR_XTES"})][2]
Local nPosQtd       := aPosCpo[Ascan(aPosCpo,{|x| AllTrim(Upper(x[1])) == "LR_QUANT"})][2]


If !ExistDir(cDirSrv)     
    MakeDir(cDirSrv)
EndIF

nHdl := fCreate(cDirSrv+_cArqTxRT)
If nHdl == -1
		MsgAlert("O arquivo de nome "+_cArqTxRT +" nao pode ser criado, favor verficar a instalacao da integracao","Atencao!")
		Return
Endif            

cLin := "000-000 = 0200" + cEOL
cLin += "011-000 = 800300" + cEOL
cLin += "001-000 = "+Alltrim(M->LQ_NUM) + cEOL
cLin += "040-000 = "+Alltrim(M->LQ_OPFAR) + cEOL
cLin += "012-000 = "+Alltrim(M->LQ_NSU) + cEOL
cLin += "940-000 = 003" + cEOL
cLin += "942-000 = 23153943002012" + cEOL //Alterar para filial da farmácia - 23153943002012
cLin += "941-000 = 001" + cEOL //Alterar para filial da farmácia
cLin += "023-000 = "+StrTran(Time(),":","") + cEOL
cLin += "022-000 = "+SubStr(dTos(dDataBase),5,2)+SubStr(dTos(dDataBase),7,2) + cEOL
IF Alltrim(M->LQ_CARPOP) <> ''
    cLin += "953-000 = "+StrTran(Alltrim(M->LQ_CARPOP),'.','') + cEOL
EndIF
cLin += "002-000 = "+"900"+Alltrim(M->LQ_NUM) + cEOL
cLin += "900-000 = 0"+ cEOL

For nX:=1 to Len(aCols)
        IF aCols[nX,nPosXTES] = 'DES'
            nQuant++
        EndIf
Next nX

IF nQuant > 12
    msgAlert("Nao pode ser feito tenda com mais 12 itens com desconto do portal!","Atencao")
    lRet:= .F.
    fClose(nHdl)
    Return lRet
EndIF

cLin += "901-000 = "+Alltrim(Str(nQuant))+ cEOL

cChave:="000"
For nX:=1 to Len(aCols)
    IF aCols[nX,nPosXTES] = 'DES'
        cLin += "902-"+cChave+" = "+Alltrim(POSICIONE("SB1",1,xFilial("SB1")+aCols[nX,nPosProd],"B1_CODBAR")) + cEOL
        cLin += "906-"+cChave+" = U"+ cEOL
        cLin += "905-"+cChave+" = "+Alltrim(Str(aCols[nX,nPosQtd])) + cEOL
        cLin += "910-"+cChave+" = "+Alltrim(Str(POSICIONE("DA1",1,xFilial("DA1")+GetMV("MV_TABPAD")+aCols[nX,nPosProd],"DA1_PRCVEN"))) + cEOL
        cLin += "911-"+cChave+" = "+Alltrim(Str(aCols[nX,nPosVlrI]))+ cEOL
        cChave:=Soma1(cChave)
    EndIf
Next nX



If fWrite(nHdl,cLin,Len(cLin)) != Len(cLin)
    MsgAlert("Ocorreu um erro na gravaco do arquivo favor contactar a TI.","Atencao!")
    fClose(nHdl)
    lRet:=.F.
    Return lRet
Else
    fClose(nHdl)
    If CpyS2T( cDirSrv+_cArqTxRT , cDirArq )
        lRet:=.T.
    Else
        msgAlert('Copia do arquivo do sevidor: "'+cDirSrv+_cArqTxRT +'" para a pasta local: "'+cDirArq+_cArqTxRT +'" ocorreu erro, favor comunciar a TI, integracao nao sera possivel!',"Atencao")
        lRet:=.F.
        Return lRet
    EndIF

Endif

Return lRet


/*
______________________________________________________________________________
|_____________________________________________________________________________|
|Programa  - MLOJA00F    Autor  Fabricio Antunes      Data   26/05/2021   	  |
|_____________________________________________________________________________|
|Descricao|Funcao para leitura do retorno de confirmacao de transacao         |
|         |                                                                   |
|_________|___________________________________________________________________|
|Uso      | Coopervap                                                         | 
|_________|___________________________________________________________________|
|_____________________________________________________________________________|
*/

User Function MLOJA06F

Local aFiles  := {}
Local aDados  := {}
Local lLoop:=.T.
Local nEspera:=5000
Local nX, nY
Local lRet:=.F.
Local aProd:={}
Local nItem:=0
Local aCompro:={}
Local nPosProd		:= aPosCpo[Ascan(aPosCpo,{|x| AllTrim(Upper(x[1])) == "LR_PRODUTO"})][2]
Local nPosQtd       := aPosCpo[Ascan(aPosCpo,{|x| AllTrim(Upper(x[1])) == "LR_QUANT"})][2]

While lLoop
    Sleep( nEspera )
    aFiles := Directory(cDirRet+"*.001")

    IF Len(aFiles) >= 1
        
        For nX := 1 To Len(aFiles)
            IF Alltrim(aFiles[nX,1]) == _cArqTxRT
                lLoop:=.F.
                FT_FUSE(cDirRet+aFiles[nX,1]) 
                FT_FGOTOP() 	
                aDados:={}					
                While !FT_FEOF()
                    cBuffer := FT_FREADLN() 
                    cBuffer := StrTran(cBuffer," = ","-")
                    aaDD(aDados,StrTokArr( cBuffer, '-' ))
                    FT_FSKIP() 
                EndDo
                FT_FUSE()
                //FErase(cDirRet+aFiles[nX,1])
                nItem:=0
                For nY:=1 to Len(aDados)
                    lRet:=.T.
                    /*Estrutura do aProd
                        1 - Indice
                        2 - Produto
                        3 - Quantidade
                        4 - Preço Bruto
                        5 - Preço Liquido
                        6 - Valor a receber
                        7 - % Desconto
                        8 - Satatus de erro*/
                    IF aDados[nY,1] = '902'
                        nItem++
                        aaDD(aProd,{nItem,aDados[nY,3],nil,nil,nil,nil,nil,nil})
                    ElseIF aDados[nY,1] = '905'
                        aProd[nItem,3]:= Val(aDados[nY,3])
                    ElseIF aDados[nY,1] = '910'
                        aProd[nItem,4]:= Val(SubStr(aDados[nY,3],1,Len(aDados[nY,3])-2)+'.'+SubStr(aDados[nY,3],Len(aDados[nY,3])-1,2))
                    ElseIF aDados[nY,1] = '911'
                        aProd[nItem,5]:= Val(SubStr(aDados[nY,3],1,Len(aDados[nY,3])-2)+'.'+SubStr(aDados[nY,3],Len(aDados[nY,3])-1,2))
                    ElseIF aDados[nY,1] = '912'
                        aProd[nItem,6]:= Val(SubStr(aDados[nY,3],1,Len(aDados[nY,3])-2)+'.'+SubStr(aDados[nY,3],Len(aDados[nY,3])-1,2))
                    ElseIF aDados[nY,1] = '909'
                        aProd[nItem,7]:= Val(SubStr(aDados[nY,3],1,Len(aDados[nY,3])-2)+'.'+SubStr(aDados[nY,3],Len(aDados[nY,3])-1,2))
                    ElseIF aDados[nY,1] = '029'
                        aaDD(aCompro,aDados[nY,3])
                    ElseIf aDados[nY,1] = '009'
                        IF aDados[nY,3] <> '00' .AND. aDados[nY,3] <> '01' .AND. aDados[nY,3] <> '02' .AND. aDados[nY,3] <> '03';
                           .AND. aDados[nY,3] <> '04' .AND. aDados[nY,3] <> '05' .AND. aDados[nY,3] <> '06' .AND. aDados[nY,3] <> '07';
                           .AND. aDados[nY,3] <> '08' .AND. aDados[nY,3] <> '09'
                                lRet:=.F.
                                //msgAlert("Portal da drogaria nao confirmou a trasacao favor verificar, venda nao podera ser finalizada","Atencao")
                                Return lRet

                        EndIF
                    EndIF
                Next nX
                dbSelectArea("SB1")
                SB1->(dbSetOrder(1))


                For nX:=1  to Len(aCols)
                    IF SB1->(dbSeek(xFilial("SB1")+aCols[nX,nPosProd]))
                        For nY:=1 to Len(aProd)
                            IF SB1->B1_CODBAR = aProd[nY,2]
                                IF aProd[nY,3] <> aCols[nX,nPosQtd]
                                    lRet:=.F.
                                    msgAlert("A quantidade aprovada para desconto no portal difere da quantidade da venda, venda nao podera ser finalizada","Atencao")
                                    Return lRet
                                EndIf
                            EndIF
                        Next nY
                    EndIF   
                Next nX


                //Se tudo ok faz impressao de comprovante   
                IF lRet
                    For nY:= 1 to 2
                        cString:=""
                        cNumOrc  :=M->LQ_NUM 
                        cCli := M->LQ_CLIENTE

                        cString += TAG_CENTER_INI+TAG_NEGRITO_INI+"COOP. AGROP, DO VALE DO PARACATU LTDA"+TAG_NEGRITO_FIM+TAG_CENTER_FIM+CHR(10)+CHR(13)
                        cString += TAG_CENTER_INI+TAG_NEGRITO_INI+"CNPJ: 23.153.943/0020-12"+TAG_NEGRITO_FIM+TAG_CENTER_FIM+CHR(10)+CHR(13)+CHR(10)+CHR(13)
                        cString += TAG_CENTER_INI+TAG_NEGRITO_INI+"*** FARMACIA COOPERVAP ***"+TAG_NEGRITO_FIM+TAG_CENTER_FIM+CHR(10)+CHR(13)+CHR(10)+CHR(13)
                        cString += TAG_CENTER_INI+TAG_NEGRITO_INI+"DATA: "+dToc(dDataBase)+" HORA: "+SubStr(TIME(),1,5)+TAG_NEGRITO_FIM+TAG_CENTER_FIM+CHR(10)+CHR(13)+CHR(10)+CHR(13) 
                        
                        For nX:= 1 to Len(aCompro)
                            cString += aCompro[nX]+CHR(10)+CHR(13)
                        Next nX
                        
                    
                        cString +=CHR(10)+CHR(13)+CHR(10)+CHR(13)+CHR(10)+CHR(13)
                        STWPrintTextNotFiscal(cString)

                        cString := TAG_GUIL_INI+TAG_GUIL_FIM
                        //STWPrintTextNotFiscal(cString)
                    Next nY
                    
                EndIF                
                Exit
            EndIF
        Next nX
    EndIF                
 
    IF lLoop
        IF msgYesNo("O sistema ainda nao obteve o retorno da integracao deseja aguardar mais "+Alltrim(Str(nEspera/1000))+" segundos?")
            Sleep( nEspera )
            nEspera+=5000
        Else
            lLoop:=.F.
        EndIF
    EndIF
EndDo


Return lRet


/*
______________________________________________________________________________
|_____________________________________________________________________________|
|Programa  - MLOJA06G    Autor  Fabricio Antunes      Data   26/05/2021   	  |
|_____________________________________________________________________________|
|Descricao|Funcao gercao confirmacao final da transacao                       |
|         |                                                                   |
|_________|___________________________________________________________________|
|Uso      | Coopervap                                                         | 
|_________|___________________________________________________________________|
|_____________________________________________________________________________|
*/



User Function MLOJA06G
Local nHdl


If !ExistDir(cDirSrv)     
    MakeDir(cDirSrv)
EndIF

nHdl := fCreate(cDirSrv+_cArqTxFN)
If nHdl == -1
		MsgAlert("O arquivo de nome "+_cArqTxFN +" nao pode ser criado, favor verficar a instalacao da integracao","Atencao!")
		Return
Endif            

cLin := "000-000 = 0202" + cEOL
cLin += "011-000 = 800300" + cEOL
cLin += "001-000 = "+Alltrim(SL1->L1_NUM) + cEOL
cLin += "040-000 = "+Alltrim(SL1->L1_OPFAR) + cEOL
cLin += "012-000 = "+Alltrim(SL1->L1_NSU) + cEOL
cLin += "940-000 = 003" + cEOL
cLin += "942-000 = 23153943002012" + cEOL //Alterar para filial da farmácia - 23153943002012
cLin += "941-000 = 001" + cEOL //Alterar para filial da farmácia
cLin += "023-000 = "+StrTran(Time(),":","") + cEOL
cLin += "022-000 = "+SubStr(dTos(dDataBase),5,2)+SubStr(dTos(dDataBase),7,2) + cEOL



If fWrite(nHdl,cLin,Len(cLin)) != Len(cLin)
    MsgAlert("Ocorreu um erro na gravaco do arquivo favor contactar a TI.","Atencao!")
    fClose(nHdl)
Else
    fClose(nHdl)
    If !CpyS2T( cDirSrv+_cArqTxFN , cDirArq )
         msgAlert('Copia do arquivo do sevidor: "'+cDirSrv+_cArqTxFN +'" para a pasta local: "'+cDirArq+_cArqTxFN +'" ocorreu erro, favor comunciar a TI, integracao nao foi finalizada!',"Atencao")
    EndIF

Endif

Return 
