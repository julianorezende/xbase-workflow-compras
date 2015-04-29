#include "rwmake.ch"
#include "TbiConn.ch"
#include "TbiCode.ch"

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณRETWFSC8  บAutor  ณON LINE CONSULTOR บ Data ณ  26/10/11   บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ                                                            บฑฑ
ฑฑบ          ณ                                                            บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ AP                                                        บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/
User Function Retwfsc8(__aCookies,__aPostParms,__nProcID,__aProcParms,__cHTTPPage)

	Local aCab   :={}
	Local aItem  := {}
	Local nUsado := 0
	Local i, ny   
//	Public cFilAnt:=U_RetriveParm (__aPostParms, "WFFILIAL")

	
	Private cBarra:=	Iif(IsSrvUnix(),"/","\")   
	Private cEmpWin:=   Iif(IsSrvUnix(),"01","01")

	cEmpresa:= U_RetriveParm (__aPostParms, "WFEMPRESA")
	cFil_:= U_RetriveParm (__aPostParms, "WFFILIAL")
//    Private cFilAnt:=cFil_
//	Private aRelImp := MaFisRelImp("MT150",{"SC8"})	
	RESET ENVIRONMENT 
	RpcSetType( 3 )
	PREPARE ENVIRONMENT EMPRESA cEmpresa FILIAL cFil_ MODULO "COM"
	RpcSetEnv( cEmpresa, cFil_,,,"COM")
	Private aRelImp := MaFisRelImp("MT150",{"SC8"})	
	cNumSc8:=	 U_RetriveParm (__aPostParms, "C8_NUM")  //	Substr(cBuffer,aT("C8_NUM",sBuffer)+7,6)
    cAprov:=		U_RetriveParm (__aPostParms, "APROVACAO")
	cMotivo:=		U_RetriveParm (__aPostParms, "C8_OBS")
	cFornece:=		U_RetriveParm (__aPostParms, "C8_FORNECE")
	cLoja:=			U_RetriveParm (__aPostParms, "C8_LOJA")
	
	dbSelectArea("SC8")
	dbSetOrder(1)
	dbSeek( xFilial("SC8") + PadR(cNumSc8,TamSx3("C8_NUM")[1]) + PadR(cFornece,TamSx3("A2_COD")[1]) + PadR(cLoja,TamSx3("A2_LOJA")[1]) )
	If Found()
		ConOut("ENCONTRADO - Retorno da Cotacao: Empresa:"+cEmpresa+" / Filial: "+cFil_+" / "+cNumSc8)
		// Cotacao Recebida
		if cAprov = "S"
			
			nVlDesc:=		Val( StrTran(U_RetriveParm (__aPostParms, "VLDESC"),",",".") )

			nValFre:=		Val( StrTran(U_RetriveParm (__aPostParms, "VALFRE"),",",".") )

			cFrete:=		U_RetriveParm (__aPostParms, "FRETE")

			cCondPg:=		U_RetriveParm (__aPostParms, "PAGAMENTO")
			
			nSomaPed:=		CalcTot(__aPostParms)
			
			//grava no SC8
			nCnt:=	1
			While .T.
				
			  For i := 1 To Len (__aPostParms)
			    If __aPostParms[i, 1] == "IT.ITEM."+cValToChar(nCnt)
			      lAchou:=.T.
			      Exit
			    EndIf
			  Next i          
          
			   If lAchou .And. i<=Len (__aPostParms)        
			
							
									cItem:=	U_RetriveParm (__aPostParms, "IT.ITEM."+cValToChar(nCnt))
		
						dbSelectArea("SC8")
						dbSetOrder(1)
						dbSeek( xFilial("SC8") + PadR(cNumSc8,TamSx3("C8_NUM")[1]) + PadR(cFornece,TamSx3("A2_COD")[1]) + PadR(cLoja,TamSx3("A2_LOJA")[1]) + cItem )
						
						If Found()
		
							//caso o prazo tenha vencido n๏ฟฝo permite gravacao
							If SC8->C8_VALIDA < dDatabase
								//Envio WF avisando que o Fornecedor foi desclassificado
								Private cMailBox := AllTrim(WFGetMV( "MV_WFMLBOX", "" ))
								Private cTo      := AllTrim(SA2->A2_EMAIL)
								Private oMail    := TWFMail():New()
								Private oMailBox := oMail:GetMailBox( cMailBox )
				
								Private cHtml    := ""
								Private cSubject := "Desclassifica็ใo por Data - Cota็ใo "+SC8->C8_NUM
								Private cBody    := "Desclassifica็ใo por Data - Cota็ใo "+SC8->C8_NUM
								Private aAttachs := {}
								oMailBox:NewMessage( cTo,,, cSubject, cBody, aAttachs )
								oMailBox:Send() //Enviando email
		
								Exit //Fim do While
		
							EndIf
										
							//BASE DO ICMS
							MaFisIni(PadR(cFornece,TamSx3("A2_COD")[1]) ,PadR(cLoja,TamSx3("A2_LOJA")[1]),"F","N","R",aRelImp)
							MaFisIniLoad(1)
							For nY := 1 To Len(aRelImp)
								MaFisLoad(aRelImp[nY][3],SC8->(FieldGet(FieldPos(aRelImp[nY][2]))),1)
							Next nY
							MaFisEndLoad(1)
							
							cVar:=			"IT.PRODUTO."+cValToChar(nCnt)
							cProduto:=		U_RetriveParm (__aPostParms, cVar)
							
							DbSelectArea("SA2")
							DbSetOrder(1)
							DbSeek(xFilial("SA2")+SC8->(C8_FORNECE+C8_LOJA))
							
							dbSelectArea("SB1")
							dbSetOrder(1)
							dbSeek( xFilial("SB1") + cProduto )
							cIcm := SC8->C8_PICM
												
							RecLock("SC8",.f.)
		
							SC8->C8_WFCO   := "100004"
		
							cVar:=			"IT.PRECO."+cValToChar(nCnt)
							cVar2:=			"IT.VALOR."+cValToChar(nCnt)
							nPreco:=		Val( StrTran(U_RetriveParm (__aPostParms, cVar),",",".") )
		
							SC8->C8_PRECO  := nPreco					
							SC8->C8_TOTAL  := Round(nPreco * SC8->C8_QUANT,2)
		                                                        
							cVar:=			"IT.IPI."+cValToChar(nCnt)					
							nIpi:=			Val(U_RetriveParm (__aPostParms, cVar))
							
							SC8->C8_ALIIPI := nIpi
		
							//caso o IPI n๏ฟฝo seja zero
							If nIpi > 0
								SC8->C8_VALIPI  := Round((SC8->C8_TOTAL * nIpi) / 100,2)
								SC8->C8_BASEIPI := SC8->C8_TOTAL
						 	EndIf
							
							cVar:=			"IT.PRAZO."+cValToChar(nCnt)
							nPrazo:=		Val(U_RetriveParm (__aPostParms, cVar)) 
							
							SC8->C8_PRAZO:= nPrazo
							
							//caso o icm nao seja zero
							MaFisAlt("IT_ALIQICM",cIcm,1)
							SC8->C8_PICM        := MaFisRet(1,"IT_ALIQICM")
							
							If SC8->C8_PICM >0
								SC8->C8_BASEICM     := SC8->C8_TOTAL
								MaFisAlt("IT_VALICM",cIcm,1)
								SC8->C8_VALICM      := MaFisRet(1,"IT_VALICM")
							EndIf
		
							SC8->C8_COND   := cCondPg
							SC8->C8_TPFRETE:= Substr(cFrete,1,1)
		
							
							If cFrete == "FOB"
								SC8->C8_VALFRE := 0
							Else
								SC8->C8_VALFRE := SC8->C8_TOTAL / nSomaPed * nValFre					
							Endif
								
							If nVlDesc = 0
								SC8->C8_VLDESC := 0
							Else
							    SC8->C8_VLDESC := SC8->C8_TOTAL / nSomaPed * nVlDesc
							Endif
							
							MsUnlock()
							MaFisEnd()
						
						Endif
				     Else
					Exit
				EndIf				
					
				nCnt ++
				
			End
			
		Else //caso tenha sido rejeitado
			
			
			aCab := {	{"C8_NUM"		,SC8->C8_NUM,NIL}}
			
			nCnt:=	1
			While .T.
				
				                                             
			  For i := 1 To Len (__aPostParms)
			    If __aPostParms[i, 1] == "IT.ITEM."+cValToChar(nCnt)
			      lAchou:=.T.
			      Exit
			    EndIf
			  Next i          
          
			   If lAchou .And. i<=Len (__aPostParms)        
			
					
							cItem:=	U_RetriveParm (__aPostParms, "IT.ITEM."+cValToChar(nCnt))
			
							dbSelectArea("SC8")
							dbSetOrder(1)
							dbSeek( xFilial("SC8") + PadR(cNumSc8,TamSx3("C8_NUM")[1]) + PadR(cFornece,TamSx3("A2_COD")[1]) + PadR(cLoja,TamSx3("A2_LOJA")[1]) + cItem )
							If Found()
								//caso o prazo tenha vencido n๏ฟฝo permite gravacao
								If SC8->C8_VALIDA < dDatabase
									//Envio WF avisando que o Fornecedor foi desclassificado
									Private cMailBox := AllTrim(WFGetMV( "MV_WFMLBOX", "" ))
									Private cTo      := AllTrim(SA2->A2_EMAIL)
									Private oMail    := TWFMail():New()
									Private oMailBox := oMail:GetMailBox( cMailBox )
					
									Private cHtml    := ""
									Private cSubject := "Desclassifica็ใo por Data - Cota็ใo "+SC8->C8_NUM
									Private cBody    := "Desclassifica็ใo por Data - Cota็ใo "+SC8->C8_NUM
									Private aAttachs := {}
									oMailBox:NewMessage( cTo,,, cSubject, cBody, aAttachs )
									oMailBox:Send() //Enviando email
			
									Exit //Fim do While
			
								EndIf
			
								cEmailComp := SC8->C8_WFEMAIL
							
								lMsErroAuto := .F.
							
								aadd(aItem,   {	{"C8_NUM"		,SC8->C8_NUM,NIL},;
												{"C8_ITEM",			SC8->C8_ITEM 	,NIL},;
												{"C8_FORNECE",		SC8->C8_FORNECE	,NIL},;
												{"C8_LOJA",			SC8->C8_LOJA	,NIL}})
								
//								MSExecAuto({|x,y,z| mata150(x,y,z)},aCab,aItem,5) //EXCLUI

								cQuery := " UPDATE "+RETSQLNAME("SC8")                                
								cQuery += " SET D_E_L_E_T_='*', R_E_C_D_E_L_=R_E_C_N_O_ "
								cQuery += " WHERE C8_NUM = '"+cNumSc8+"'  AND C8_FILIAL = '" + XFILIAL("SC8") "
								cquery += "' AND C8_FORNECE = '"+cFornece+"' AND C8_LOJA = '"+cLoja+"' AND D_E_L_E_T_ = ' ' "

								TcSqlExec(cQuery)
								
								If lMsErroAuto
									ConOut("Erro na Exclusใo do Participante, Fornecedor: "+SC8->(C8_FORNECE+C8_LOJA)+" Cotacao: "+SC8->C8_NUM)
								Else
									ConOut("Participante excluido com sucesso, Fornecedor: "+SC8->(C8_FORNECE+C8_LOJA)+" Cotacao: "+SC8->C8_NUM)
								Endif
								
							Endif
			     Else
					Return '<img src="img/banner.png" width="774" height="247" alt="Ok" />'
				EndIf
				nCnt ++
				
			End
			
			//Envio do WF com aviso de Desistencia do Fornecedor.
			Private cMailBox := AllTrim(WFGetMV( "MV_WFMLBOX", "" ))
			Private cTo      := AllTrim(cEmailComp)
			Private oMail    := TWFMail():New()
			Private oMailBox := oMail:GetMailBox( cMailBox )

			Private cHtml    := ""
			Private cSubject := "Desistencia do processo de cota็ใo do Fornecedor "+SC8->C8_FORNECE+" - " + Posicione("SA2",1,XFILIAL("SA2")+SC8->(C8_FORNECE+C8_LOJA),"A2_NOME")
			Private cBody    := cSubject
			Private aAttachs := {}
			oMailBox:NewMessage( cTo,,, cSubject, cBody, aAttachs )
			oMailBox:Send() //Enviando email
			
		endif
		
	Else

		ConOut("NAO ENCONTRADO - Retorno da Cotacao: Empresa:"+cEmpresa+" / Filial: "+cFil_+" / "+cNumSc8)

	Endif
	
	//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
	//ณ O arquivo texto deve ser fechado, bem como o dialogo criado na fun- ณ
	//ณ cao anterior.                                                       ณ
	//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
	

Return '<img src="img/banner.png" width="774" height="247" alt="Ok" />'                         


Static Function CalcTot(__aPostParms)
	Local nCnt:=	1    
	Local nSoma:=	0
	Local i
	
	While .T.

         
  For i := 1 To Len (__aPostParms)
    If __aPostParms[i, 1] == "IT.PRECO."+cValToChar(nCnt)
      lAchou:=.T.
      Exit
    EndIf
  Next i          
          
   If lAchou .And. i<=Len (__aPostParms)        

		cVar:=			"IT.PRECO."+cValToChar(nCnt)
		nPreco:=		Val( StrTran(U_RetriveParm (__aPostParms, cVar),",",".") )

		cVar:=			"IT.QUANT."+cValToChar(nCnt)
		nQuant:=		Val( StrTran(U_RetriveParm (__aPostParms, cVar),",",".") )
		
		nSoma+=			nPreco * nQuant 
	Else	
		Return (nSoma)
	EndIf	
		nCnt ++
		
	End                                        

Return(nSoma)