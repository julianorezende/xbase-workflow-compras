#include "rwmake.ch"
#include "TbiConn.ch"
#include "TbiCode.ch"

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³RETWFSC7  ºAutor  ³ON LINE CONSULTOR º Data ³  26/10/11   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³                                                            º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ AP                                                        º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
User Function Retwfsc7(__aCookies,__aPostParms,__nProcID,__aProcParms,__cHTTPPage)


	Private cBarra:=	Iif(IsSrvUnix(),"/","\")   
	Private cEmpWin:=   Iif(IsSrvUnix(),"01","01")

	cEmpresa:= U_RetriveParm (__aPostParms, "WFEMPRESA")
	cFil_:= U_RetriveParm (__aPostParms, "WFFILIAL")
	
	RESET ENVIRONMENT 
	RpcSetType( 3 )
	PREPARE ENVIRONMENT EMPRESA cEmpresa FILIAL cFil_ MODULO "COM"
	RpcSetEnv( cEmpresa, cFil_,,,"COM")
	
	cNumSc7:=		U_RetriveParm (__aPostParms, "PEDIDO")
    cAprovacao:=	U_RetriveParm (__aPostParms, "APROVACAO")
	cMotivo:=		U_RetriveParm (__aPostParms, "LBMOTIVO")
	cAprov:=		U_RetriveParm (__aPostParms, "CAPROV")
	  
	dbSelectArea("SC7")
	dbSetOrder(1)
	DbSeek(xfilial("SC7")+cNumSc7)
	If Found() // achou 
	
		If cAprovacao = "S" // foi aprovado pelo email

			ConOut('Processando a Aprovação do pedido de compra: '+SC7->C7_NUM)
		
			If SC7->C7_CONAPRO == "B" .AND. !PedJaRep()
			
				DBSELECTAREA("SCR")
				DbSetorder(2)
				DbSeek(xFilial("SCR")+"PC"+SC7->C7_NUM)
				nTotLib:=	0
				If SCR->CR_TOTAL < GetNewPar("UN_LIMAPRO",80000)
					lLibPed:=	.T.
					nTotLib:=	1
				Else
					lLibPed:=	.F.
					//Contador de Aprovadores
					cQuery:=	"SELECT COUNT(*) AS TOT FROM "+RETSQLNAME("SCR") + " SCR "
					cQuery+=		"WHERE  CR_NUM = '" + SC7->C7_NUM + "' AND CR_FILIAL = '"+XFILIAL("SCR")+ "' AND CR_STATUS = '03' AND SCR.D_E_L_E_T_ = ' ' "
					dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQuery),"TRBL", .F., .T.)
					
					nTotLib :=	TRBL->TOT
					
					If nTotLib >= 1 //Libera Pedido
						lLibPed:=	.T.
					Endif    
					DbSelectArea("TRBL")
					TRBL->(DbCloseArea())	
				Endif
					
				DBSelectarea("SCR")                   // Posiciona a Liberacao
				DbSetorder(2)
				DbSeek(xFilial("SCR")+"PC"+SC7->C7_NUM)
				While !Eof() .And. SC7->C7_NUM == ALLTRIM(SCR->CR_NUM) 
					RecLock("SCR",.f.)
					SCR->CR_DataLib := dDataBase
					SCR->CR_Obs     := cMotivo
					If cAprov = SCR->CR_USER
						SCR->CR_STATUS  := "03"
						SCR->CR_USERLIB := SCR->CR_USER
						SCR->CR_LIBAPRO := SCR->CR_APROV
					Else
						If nTotLib >= 1 .and. SCR->CR_STATUS <> "03"
							SCR->CR_STATUS  := "05"					
						Endif
					Endif
					MsUnLock()
					DbSelectarea("SCR")
					DbSkip()
				End
				
				If lLibPed
					WFW120Pf() // Manda email para fornecedor
				Endif
				
			Else                    
				Private _cNomeRep:=	""
				If PedJaRep()
					//Envio WF avisando que o pedido ja foi REPROVADO
					PutMv("MV_WFHTML","T")
					oProcess:=TWFProcess():New("PEDCOM","WORKFLOW PARA APROVACAO DE PC")
					oProcess:NewTask('Inicio',cBarra+"workflow"+cBarra+"htm"+cBarra+"pedwf006.htm")
					PswOrder(1)
					If PswSeek(cAprov,.t.)
						aInfo   := PswRet(1)
						_cMailTo 	:= alltrim(aInfo[1,14])
					Endif
					oHtml   := oProcess:oHtml                        
					oHtml:valbyname("Num"		, SC7->C7_NUM)
			        oHtml:valbyname("Req"    	, _cNomeRep)
				    oHtml:valbyname("Emissao"   , SC7->C7_EMISSAO)
				    oHtml:valbyname("Motivo"   , cMotivo)
/*					Private cMailBox := AllTrim(WFGetMV( "MV_WFMLBOX", "" ))
					Private cTo      := _cMailTo
					Private oMail    := TWFMail():New()
					Private oMailBox := oMail:GetMailBox( cMailBox )

					Private cHtml    := ""
					Private cSubject := "Pedido já Reprovado anteriormente"
					Private cBody    := "O PEDIDO "+SC7->C7_NUM+" JA FOI REPROVADO PELO APROVADOR "+UPPER(Alltrim(_cNomeRep))+"."
					Private aAttachs := {}
					oMailBox:NewMessage( cTo,,, cSubject, cBody, aAttachs )
					oMailBox:Send() //Enviando email  
*/
					cQuery2 := " SELECT C7_ITEM, C7_PRODUTO, C7_DESCRI "
					cQuery2 += " FROM "+RetSqlName('SC7')+" SC7"
					cQuery2 += " WHERE C7_NUM = '"+cNumSc7+"' AND C7_FILIAL = '" + XFILIAL("SC7") + "' AND SC7.D_E_L_E_T_ = ' ' "
					
					dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQuery2),"TRB", .F., .T.)
				
					If !TRB->(EOF())
					
						dbSelectArea("TRB")
						dbGoTop()   
						While !EOF()
							aadd(oHtml:ValByName("it.Item")		, TRB->C7_ITEM)
							aadd(oHtml:ValByName("it.Cod")		, TRB->C7_PRODUTO)
							aadd(oHtml:ValByName("it.Desc")		, TRB->C7_DESCRI)
							dbSkip()
						End
					EndIf
					TRB->(dbCloseArea())
				
					//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
					//³Funcoes para Envio do Workflow³
					//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
					//envia o e-mail
					//cMailSol 	:= UsrRetMail(cCodUsr)
					cUser 			  := "Administrador"
					oProcess:ClientName(cUser)
					CONOUT("e-MAIL: "+_cMailTo)
					CONOUT("USERCOD "+cAprov)
					oProcess:cTo	  := _cMailTo 
					oProcess:cSubject := "O PEDIDO "+SC7->C7_NUM+" JA FOI REPROVADO PELO APROVADOR "+UPPER(Alltrim(_cNomeRep))+"."
					oProcess:cBody    := ""
					oProcess:bReturn  := ""
					oProcess:Start()
				
					/*
					RastreiaWF( ID do Processo, Codigo do Processo, Codigo do Status, Descricao Especifica, Usuario )
					If cAprov == "L" //Verifica se foi aprovado
						RastreiaWF(oProcess:fProcessID+'.'+oProcess:fTaskID,"PEDCOM",'100500',"APROVACAO DE WORKFLOW DE SC",cUsername)
					ElseIf cAprov == "R" //Verifica se foi rejeitado
						RastreiaWF(oProcess:fProcessID+'.'+oProcess:fTaskID,"PEDCOM",'100600',"REJEICAO DE WORKFLOW DE SC",cUsername)
					EndIf
				    */
					oProcess:Free()
					oProcess:Finish()
					oProcess:= Nil                  
					WFSendMail({cEmpAnt,cFilAnt})
				EndIf
				
				If SC7->C7_CONAPRO == "L"
					//Executa a Liberacao com Codigo 03 do Aprovador.
					DBSelectarea("SCR")
					DbSetorder(2)
					DbSeek(xFilial("SCR")+"PC"+SC7->C7_NUM+Space(44)+cAprov)
					If Found()
						RecLock("SCR",.f.)
						SCR->CR_DataLib := dDataBase
						SCR->CR_Obs     := cMotivo
						SCR->CR_STATUS  := "03"
						SCR->CR_USERLIB := SCR->CR_USER
						SCR->CR_LIBAPRO  := SCR->CR_APROV
						MsUnLock()
					Endif
				
				EndIf
				
			EndIf
					
		Else // Caso reprovado

			ConOut('Processando a Reprovação do pedido de compra: '+SC7->C7_NUM)

			If SC7->C7_CONAPRO == "L"
				//Enviar e-mail para o proprio aprovador
				Private _cNomeApr:=	""
				If PedJaApr()

					PswOrder(1)
					If PswSeek(cAprov,.t.)
						aInfo   := PswRet(1)
						_cMailTo 	:= alltrim(aInfo[1,14])
					Endif
				
					//Envio WF avisando que o pedido ja foi APROVADO
					PutMv("MV_WFHTML","T")
					oProcess:=TWFProcess():New("PEDCOM","WORKFLOW PARA APROVACAO DE PC")
					oProcess:NewTask('Inicio',cBarra+"workflow"+cBarra+"htm"+cBarra+"pedwf005.htm")
					PswOrder(1)
					If PswSeek(cAprov,.t.)
						aInfo   := PswRet(1)
						_cMailTo 	:= alltrim(aInfo[1,14])
					Endif
					oHtml   := oProcess:oHtml                        
					oHtml:valbyname("Num"		, SC7->C7_NUM)
			        oHtml:valbyname("Req"    	, _cNomeRep)
				    oHtml:valbyname("Emissao"   , SC7->C7_EMISSAO)
				    oHtml:valbyname("Motivo"   , cMotivo)					
/*
					Private cMailBox := AllTrim(WFGetMV( "MV_WFMLBOX", "" ))
					Private cTo      := _cMailTo
					Private oMail    := TWFMail():New()
					Private oMailBox := oMail:GetMailBox( cMailBox )

					Private cHtml    := ""
					Private cSubject := "Pedido já Aprovado anteriormente"
					Private cBody    := "O PEDIDO "+SC7->C7_NUM+" JA FOI APROVADO PELO APROVADOR "+UPPER(Alltrim(_cNomeApr))+"."
					Private aAttachs := {}
					oMailBox:NewMessage( cTo,,, cSubject, cBody, aAttachs )
					oMailBox:Send() //Enviando email
*/					
					cQuery2 := " SELECT C7_ITEM, C7_PRODUTO, C7_DESCRI "
					cQuery2 += " FROM "+RetSqlName('SC7')+" SC7"
					cQuery2 += " WHERE C7_NUM = '"+cNumSc7+"' AND C7_FILIAL = '" + XFILIAL("SC7") + "' AND SC7.D_E_L_E_T_ = ' ' "
					
					dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQuery2),"TRB", .F., .T.)
				
					If !TRB->(EOF())
					
						dbSelectArea("TRB")
						dbGoTop()   
						While !EOF()
							aadd(oHtml:ValByName("it.Item")		, TRB->C7_ITEM)
							aadd(oHtml:ValByName("it.Cod")		, TRB->C7_PRODUTO)
							aadd(oHtml:ValByName("it.Desc")		, TRB->C7_DESCRI)
							dbSkip()
						End
					EndIf
					TRB->(dbCloseArea())
				
					//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
					//³Funcoes para Envio do Workflow³
					//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
					//envia o e-mail
					//cMailSol 	:= UsrRetMail(cCodUsr)
					cUser 			  := "Administrador"
					oProcess:ClientName(cUser)
					CONOUT("e-MAIL: "+_cMailTo)
					CONOUT("USERCOD "+cAprov)
					oProcess:cTo	  := _cMailTo 
					oProcess:cSubject := "O PEDIDO "+SC7->C7_NUM+" JA FOI APROVADO PELO APROVADOR "+UPPER(Alltrim(_cNomeApr))+"."
					oProcess:cBody    := ""
					oProcess:bReturn  := ""
					oProcess:Start()
				
					/*
					RastreiaWF( ID do Processo, Codigo do Processo, Codigo do Status, Descricao Especifica, Usuario )
					If cAprov == "L" //Verifica se foi aprovado
						RastreiaWF(oProcess:fProcessID+'.'+oProcess:fTaskID,"PEDCOM",'100500',"APROVACAO DE WORKFLOW DE SC",cUsername)
					ElseIf cAprov == "R" //Verifica se foi rejeitado
						RastreiaWF(oProcess:fProcessID+'.'+oProcess:fTaskID,"PEDCOM",'100600',"REJEICAO DE WORKFLOW DE SC",cUsername)
					EndIf
				    */
					oProcess:Free()
					oProcess:Finish()
					oProcess:= Nil                  
					WFSendMail({cEmpAnt,cFilAnt})

				EndIf
			Else
				//Contador de Aprovadores
				cQuery:=	"SELECT COUNT(*) AS TOT FROM "+RETSQLNAME("SCR") + " SCR "
				cQuery+=		"WHERE  CR_NUM = '" + SC7->C7_NUM + "' AND CR_FILIAL = '"+XFILIAL("SC7")+ "' AND CR_STATUS = '04' AND SCR.D_E_L_E_T_ = ' ' "
				dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQuery),"TRBL", .F., .T.)
				If SCR->CR_TOTAL < GetNewPar("UN_LIMAPRO",80000)
					nTotBlq:=	1
				Else
					nTotBlq:=	TRBL->TOT
				EndIf

				DBSelectarea("SCR")
				DbSetorder(2)
				DbSeek(xFilial("SCR")+"PC"+SC7->C7_NUM+Space(44)+cAprov)
				If Found()
					RecLock("SCR",.f.)
					SCR->CR_DataLib := dDataBase
					SCR->CR_STATUS  := "04" //Bloqueio    
					SCR->CR_OBS		:= cMotivo
					MsUnLock()
				Endif

				If nTotBlq >= 1
				
					_cMailTo:=	""
					
					//Pego e-mail do Comprador responsável pelo Pedido
					PswOrder(1)
					If PswSeek(SC7->C7_USER,.t.)
						aInfo   	:= PswRet(1)
						_cMailTo 	+= alltrim(aInfo[1,14])
					Endif
/*	
					//Pego e-mail do Solicitante responsável pelo Pedido
					DbSelectArea("SC1")
					DbSetOrder(1)
					DbSeek(xfilial("SC1")+SC7->C7_NUMSC)
					

					PswOrder(1)
					If PswSeek(SC1->C1_USER,.t.)
						aInfo   	:= PswRet(1)
						_cMailTo 	+= "; "+alltrim(aInfo[1,14])
					Endif
*/					
					PswOrder(1)
					If PswSeek(cAprov,.t.)
						aInfo   	:= PswRet(1)
						_cNomeRep 	:= alltrim(aInfo[1,2])
					Endif
					
	
					//Envio WF avisando que o Pedido foi Reprovado

					PutMv("MV_WFHTML","T")
					oProcess:=TWFProcess():New("PEDCOM","WORKFLOW PARA APROVACAO DE PC")
					oProcess:NewTask('Inicio',cBarra+"workflow"+cBarra+"htm"+cBarra+"pedwf006.htm")
					oHtml   := oProcess:oHtml                        
					oHtml:valbyname("Num"		, SC7->C7_NUM)
			        oHtml:valbyname("Req"    	, _cNomeRep)
				    oHtml:valbyname("Emissao"   , SC7->C7_EMISSAO)
				    oHtml:valbyname("Motivo"   , cMotivo)					
/*
					Private cMailBox := AllTrim(WFGetMV( "MV_WFMLBOX", "" ))
					Private cTo      := _cMailTo
					Private oMail    := TWFMail():New()
					Private oMailBox := oMail:GetMailBox( cMailBox )
	
					Private cHtml    := ""
					Private cSubject := "Pedido "+SC7->C7_NUM+" Reprovado...    Solic. Origem: "+SC1->C1_NUM
					Private cBody    := "O PEDIDO "+SC7->C7_NUM+" FOI REPROVADO POR "+UPPER(Alltrim(_cNomeRep))+"."
					Private aAttachs := {}
					oMailBox:NewMessage( cTo,,, cSubject, cBody, aAttachs )
					oMailBox:Send() //Enviando email
*/	                  
					cQuery2 := " SELECT C7_ITEM, C7_PRODUTO, C7_DESCRI "
					cQuery2 += " FROM "+RetSqlName('SC7')+" SC7"
					cQuery2 += " WHERE C7_NUM = '"+cNumSc7+"' AND C7_FILIAL = '" + XFILIAL("SC7") + "' AND SC7.D_E_L_E_T_ = ' ' "
					
					dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQuery2),"TRB", .F., .T.)
				
					If !TRB->(EOF())
					
						dbSelectArea("TRB")
						dbGoTop()   
						While !EOF()
							aadd(oHtml:ValByName("it.Item")		, TRB->C7_ITEM)
							aadd(oHtml:ValByName("it.Cod")		, TRB->C7_PRODUTO)
							aadd(oHtml:ValByName("it.Desc")		, TRB->C7_DESCRI)
							dbSkip()
						End
					EndIf
					TRB->(dbCloseArea())
				
					//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
					//³Funcoes para Envio do Workflow³
					//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
					//envia o e-mail
					//cMailSol 	:= UsrRetMail(cCodUsr)
					cUser 			  := "Administrador"
					oProcess:ClientName(cUser)
					CONOUT("e-MAIL: "+_cMailTo)
					CONOUT("USERCOD "+cAprov)
					oProcess:cTo	  := _cMailTo 
					oProcess:cSubject := "O PEDIDO "+SC7->C7_NUM+" FOI REPROVADO PELO APROVADOR "+UPPER(Alltrim(_cNomeRep))+"."
					oProcess:cBody    := ""
					oProcess:bReturn  := ""
					oProcess:Start()
				
					/*
					RastreiaWF( ID do Processo, Codigo do Processo, Codigo do Status, Descricao Especifica, Usuario )
					If cAprov == "L" //Verifica se foi aprovado
						RastreiaWF(oProcess:fProcessID+'.'+oProcess:fTaskID,"PEDCOM",'100500',"APROVACAO DE WORKFLOW DE SC",cUsername)
					ElseIf cAprov == "R" //Verifica se foi rejeitado
						RastreiaWF(oProcess:fProcessID+'.'+oProcess:fTaskID,"PEDCOM",'100600',"REJEICAO DE WORKFLOW DE SC",cUsername)
					EndIf
				    */
					oProcess:Free()
					oProcess:Finish()
					oProcess:= Nil                  
					WFSendMail({cEmpAnt,cFilAnt})


	    			//Como ultima acao, Muda Status
					dbselectarea("SC7")
					DBSETORDER(1)
					DBSeek(xFilial("SC87")+SC7->C7_NUM)      // Posiciona o Pedido
					_cNumOri:=	SC7->C7_NUM
					while !EOF() .and. SC7->C7_Num == _cNumOri
						RecLock("SC7",.f.)
						SC7->C7_ConaPro := "R"
						MsUnLock()
						DBSkip()
					enddo
	            
				EndIf
				DbSelectArea("TRBL")
				TRBL->(DbCloseArea())

			Endif
		Endif
		
	Else
		ConOut("O retorno de aprovação do Pedido "+cNumSc7+" nao foi encontrado!")
	EndIf
		
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ O arquivo texto deve ser fechado, bem como o dialogo criado na fun- ³
	//³ cao anterior.                                                       ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	
	
Return '<img src="img/banner.png" width="774" height="247" alt="Ok" />'


/*BEGINDOC
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Funcao para checar se o Pedido já esta REPROVADO³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
ENDDOC*/
Static Function PedJaRep()
	lRet:=.F.
	DBSelectarea("SCR")                   // Posiciona a Liberacao
	DbSetorder(2)
	DbSeek(xFilial("SCR")+"PC"+SC7->C7_NUM)
	While !Eof() .And. SC7->C7_NUM == ALLTRIM(SCR->CR_NUM)
		If SCR->CR_STATUS == "04"
			lRet:=	.T.
			If Type("_cNomeRep") == "C"
				PswOrder(1)
				If PswSeek(SCR->CR_USER,.t.)
					aInfo   	:= PswRet(1)
					_cNomeRep	:= aInfo[1,2]
				Endif
			Endif
		Endif
		DbSelectarea("SCR")
		DbSkip()
	End
Return lRet


/*BEGINDOC
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Funcao para checar se o Pedido já esta APROVADO³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
ENDDOC*/
Static Function PedJaApr()
	lRet:=.F.
	DBSelectarea("SCR")                   // Posiciona a Liberacao
	DbSetorder(2)
	DbSeek(xFilial("SCR")+"PC"+SC7->C7_NUM)
	While !Eof() .And. SC7->C7_NUM == ALLTRIM(SCR->CR_NUM)
		If SCR->CR_STATUS == "03"
			lRet:=	.T.
			If Type("_cNomeApr") == "C"
				PswOrder(1)
				If PswSeek(SCR->CR_USER,.t.)
					aInfo   	:= PswRet(1)
					_cNomeApr	:= aInfo[1,2]
				Endif
			Endif
		Endif
		DbSelectarea("SCR")
		DbSkip()
	End
Return lRet


/*BEGINDOC
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ¿
//³Funcao para Liberacao do Pedido de Compras³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙÙ
ENDDOC*/
Static Function WFW120Pf()

	dbselectarea("SC7")
	DBSETORDER(1)
	DBSeek(xFilial("SC7")+SC7->C7_NUM)      // Posiciona o Pedido
	_cNumOri:=	SC7->C7_NUM
	while !EOF() .and. SC7->C7_Num == _cNumOri
		RecLock("SC7",.f.)
		SC7->C7_ConaPro := "L"
		MsUnLock()
		DBSkip()
	enddo
	/**** Aviso o Fornecedor ****/
	dbSelectArea('SC7')
	dbSetOrder(1)
	dbSeek(xFilial('SC7')+_cNumOri)
	_oProc := TWFProcess():New( "PEDCOM", "Pedido para o Fornecedor" )
	_oProc:NewTask( "Solicitação de Pedido", "\workflow\htm\wfw120p2.htm" )
	_oProc:cSubject := "Pedido de Compra " + SC7->C7_NUM
	//		  _oProc:bReturn := "U_WFW120P( 1 )"
	oHTML := _oProc:oHTML
	/*** Preenche os dados do cabecalho ***/
	oHtml:ValByName( "EMISSAO", SC7->C7_EMISSAO )
	oHtml:ValByName( "FORNECEDOR", SC7->C7_FORNECE )
	dbSelectArea('SA2')
	dbSetOrder(1)
	dbSeek(xFilial('SA2')+SC7->C7_FORNECE)
	oHtml:ValByName( "lb_nome", SA2->A2_NREDUZ )

	//Pego as condiicoes de Pagamento
	dbSelectArea('SE4')
	DBSETORDER(1)
	dbSeek(xFilial('SE4') + SC7->C7_COND)
	ccond := SE4->E4_DESCRI
	oHtml:ValByName( "lb_cond", CCOND )

	dbSelectArea('SC7')
	dbSetOrder(1)
	dbSeek(xFilial('SC7')+cNumSc7)
	oHtml:ValByName( "PEDIDO", SC7->C7_NUM )
	cNum := SC7->C7_NUM
	nTotal := 0
	While !Eof() .and. C7_NUM = cNum
		nTotal := nTotal + C7_TOTAL
		AAdd( (oHtml:ValByName( "it.item" )),C7_ITEM )
		AAdd( (oHtml:ValByName( "it.codigo" )),C7_PRODUTO )
		dbSelectArea('SB1')
		dbSetOrder(1)
		dbSeek(xFilial('SB1')+SC7->C7_PRODUTO)
		AAdd( (oHtml:ValByName( "it.descricao" )),SB1->B1_DESC )
		AAdd( (oHtml:ValByName( "it.quant" )),TRANSFORM( SC7->C7_QUANT,'@E 999,999.99' ) )
		AAdd( (oHtml:ValByName( "it.preco" )),TRANSFORM( SC7->C7_PRECO,'@E 999,999.99' ) )
		AAdd( (oHtml:ValByName( "it.total" )),TRANSFORM( SC7->C7_TOTAL,'@E 999,999.99' ) )
		AAdd( (oHtml:ValByName( "it.unid" )),SB1->B1_UM )

		dbSelectArea('SC7')
		dbSkip()
	Enddo

	oHtml:ValByName( "lbValor" ,TRANSFORM( nTotal,'@E 999,999.99' ) )
	oHtml:ValByName( "lbFrete" ,TRANSFORM( 0,'@E 999,999.99' ) )
	oHtml:ValByName( "lbTotal" ,TRANSFORM( nTotal,'@E 999,999.99' ) )

	dbSelectArea('SC7')
	dbSetOrder(1)
	dbSeek(xFilial('SC7')+cNumSc7)
	SA2->(dbSetOrder(1))
	ConOut(xFilial("SA2")+SC7->C7_FORNECE+SC7->C7_LOJA)
	SA2->(dbSeek(xFilial("SA2")+SC7->C7_FORNECE+SC7->C7_LOJA))
	_oProc:cTo := SA2->A2_EMAIL
	ConOut("Email:"+SA2->A2_EMAIL)
	_oProc:Start()
	RastreiaWF("PEDCOM"+'.'+_oProc:fTaskID,"PEDCOM",'100007',"Pedido de Compras "+cNumSc7+" Aprovado. Enviado para o Fornecedor")
	_oProc:Finish()

Return