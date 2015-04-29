#include "rwmake.ch"
#include "TbiConn.ch"
#include "TbiCode.ch"

/*

*------------------------------------------------------------------------------------------------------------------------------------*
* Fonte      * RETWFSC1 * Autor  * CONSULTORIA ON LINE   * Benedic, Domine Deus, in hac societate quae facit.	Data *  20/01/2014   *
*------------------------------------------------------------------------------------------------------------------------------------*
* Descricão  *  Este constam as funcoes responsaveis para o tratamento de retorno da aprovacao e ou reprovacao da SC compras         *
*------------------------------------------------------------------------------------------------------------------------------------*
* Uso        * Compras			                     													                             *
*------------------------------------------------------------------------------------------------------------------------------------*
*Constultor  * Juliano Rezende Ribeiro																											 *
*------------------------------------------------------------------------------------------------------------------------------------*
*/

User Function Retwfsc1(__aCookies,__aPostParms,__nProcID,__aProcParms,__cHTTPPage)
//Return 'DEU CERTO'

	Private cBarra:=	Iif(IsSrvUnix(),"/","\")   
	Private cEmpWin:=   Iif(IsSrvUnix(),"01","01")


	cEmpresa:= U_RetriveParm (__aPostParms, "WFEMPRESA")
	cFil_:= U_RetriveParm (__aPostParms, "WFFILIAL")
	RESET ENVIRONMENT 
	RpcSetType( 3 )
	PREPARE ENVIRONMENT EMPRESA cEmpresa FILIAL cFil_ MODULO "COM"
	RpcSetEnv( cEmpresa, cFil_,,,"COM")
    
	cNumSc1:= U_RetriveParm (__aPostParms, "CNUM")
	cAprov:= U_RetriveParm (__aPostParms, "CAPROV")
	cMotivo:=U_RetriveParm (__aPostParms, "CMOTIVO")
	cCodUsr:=U_RetriveParm (__aPostParms, "CCODUSR")

	PswOrder(1)    
	PswSeek(cCodUsr,.t.)
	aInfo   	:= PswRet(1)	
	_cAprov := PswRet()[1][11]
	cAprovIni:=_cAprov                        
	nPoscAprov:=1 
	_cAprov:=Substr(cAprovIni,1,6)                        
	_cMailTo 	:= alltrim(aInfo[1,14])	

	dbSelectArea("SC1")
	dbSetOrder(1)
	DbSeek(xfilial("SC1")+cNumSc1)
	IF Empty(SC1->C1_APROV) .or. SC1->C1_APROV=="B"
	
		While !eof() .and. cNumSc1 == SC1->C1_NUM
		   
		    //ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		    //³ Grava os campos obtendo os valores da linha lida do arquivo texto.  ³
		    //ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		    
		    RecLock("SC1",.F.)                            
		    SC1->C1_APROV	:= cAprov
		    SC1->C1_OBS		+= cMotivo      
		    SC1->C1_CODAPRO := _cAprov
		    MSUnLock()
	
		    DbSelectArea("SC1")
		    dbskip()
		    
		EndDo

		DbSeek(xfilial("SC1")+cNumSc1)
		IF FOUND()
		
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³Inicia Envio de Mensagem de Aviso³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ    
	
			PutMv("MV_WFHTML","T")
			oProcess:=TWFProcess():New("PEDCOM","WORKFLOW PARA APROVACAO DE SC")
			If cAprov == "L" //Verifica se foi aprovado
				oProcess:NewTask('Inicio',cBarra+"workflow"+cBarra+"htm"+cBarra+"comwf005.htm")
			ElseIf cAprov == "R" //Verifica se foi rejeitado
				oProcess:NewTask('Inicio',cBarra+"workflow"+cBarra+"htm"+cBarra+"comwf006.htm")
			EndIf                 
			PswOrder(1)
			If PswSeek(SC1->C1_CODAPRO,.t.)
				aInfo   	:= PswRet(1)
				Req			:= aInfo[1,2]
			Endif
			oHtml   := oProcess:oHtml                        
			oHtml:valbyname("Num"		, cNumSc1)
	        oHtml:valbyname("Req"    	, Req)
		    oHtml:valbyname("Emissao"   , SC1->C1_EMISSAO)
		    oHtml:valbyname("Motivo"   , cMotivo)
		
			cQuery2 := " SELECT C1_ITEM, C1_PRODUTO, C1_DESCRI "
			cQuery2 += " FROM "+RetSqlName('SC1')+" SC1"
			cQuery2 += " WHERE C1_NUM = '"+cNumSc1+"' AND C1_FILIAL = '" + XFILIAL("SC1") + "' AND SC1.D_E_L_E_T_ = ' ' "
			
			dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQuery2),"TRB", .F., .T.)
		
			If !TRB->(EOF())
			
				dbSelectArea("TRB")
				dbGoTop()   
				While !EOF()
					aadd(oHtml:ValByName("it.Item")		, TRB->C1_ITEM)
					aadd(oHtml:ValByName("it.Cod")		, TRB->C1_PRODUTO)
					aadd(oHtml:ValByName("it.Desc")		, TRB->C1_DESCRI)
					dbSkip()
				End
			EndIf
			TRB->(dbCloseArea())
		
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³Funcoes para Envio do Workflow³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			//envia o e-mail
			cMailSol 	:= UsrRetMail(cCodUsr)
			cUser 			  := "Administrador"
			oProcess:ClientName(cUser)
			CONOUT("e-MAIL: "+cMailSol)
			CONOUT("USERCOD "+cCodUsr)
			oProcess:cTo	  := cMailSol 
			If cAprov == "L" //Verifica se foi aprovado
				oProcess:cSubject := "SC N°: "+cNumSc1+" - Aprovada"
			ElseIf cAprov == "R" //Verifica se foi rejeitado
				oProcess:cSubject := "SC N°: "+cNumSc1+" - Reprovada"
			EndIf
			oProcess:cBody    := ""
			oProcess:bReturn  := ""
			oProcess:Start()
		
			//RastreiaWF( ID do Processo, Codigo do Processo, Codigo do Status, Descricao Especifica, Usuario )
			If cAprov == "L" //Verifica se foi aprovado
				RastreiaWF(oProcess:fProcessID+'.'+oProcess:fTaskID,"PEDCOM",'100500',"APROVACAO DE WORKFLOW DE SC",cUsername)
			ElseIf cAprov == "R" //Verifica se foi rejeitado
				RastreiaWF(oProcess:fProcessID+'.'+oProcess:fTaskID,"PEDCOM",'100600',"REJEICAO DE WORKFLOW DE SC",cUsername)
			EndIf
		
			oProcess:Free()
			oProcess:Finish()
			oProcess:= Nil                  
			
			//WFSendMail({cEmpAnt,cFilAnt})
		ENDIF
		
		Else
		
		SC1JaRep() 
	EndIf
		
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ O arquivo texto deve ser fechado, bem como o dialogo criado na fun- ³
	//³ cao anterior.                                                       ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	
Return '<img src="img/banner.png" width="774" height="247" alt="Ok" />'


User Function RetriveParm (aParms, cVar)
local i
  For i := 1 To Len (aParms)
    If aParms[i, 1] == cVar
      Return aParms[i, 2]
    EndIf
  Next i
  Return



/*BEGINDOC
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Funcao para checar se o Pedido já esta REPROVADO³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
ENDDOC*/
Static Function SC1JaRep()
	lRet:=.F.
	DBSelectarea("SC1")                   // Posiciona a Solicitacao de compras
	DbSetorder(1)
	DbSeek(xfilial("SC1")+cNumSc1)
	IF SC1->C1_APROV=="R" .OR. SC1->C1_APROV=="L"
					//Envio WF avisando que o pedido ja foi REPROVADO
					PutMv("MV_WFHTML","T")      
					IF SC1->C1_APROV=="R"
					oProcess:=TWFProcess():New("PEDCOM","WORKFLOW PARA REPROVACAO DE SC")
					oProcess:NewTask('Inicio',cBarra+"workflow"+cBarra+"htm"+cBarra+"comwf006.htm")
					Else 
					oProcess:=TWFProcess():New("PEDCOM","WORKFLOW PARA APROVACAO DE SC")
					oProcess:NewTask('Inicio',cBarra+"workflow"+cBarra+"htm"+cBarra+"comwf005.htm")
					EndIf
					PswOrder(1)    
					If PswSeek(SC1->C1_CODAPRO,.t.)
						aInfo   	:= PswRet(1)
						Req			:= aInfo[1,2]                   
//						_cMailTo 	:= alltrim(aInfo[1,14])
					Endif                       
					PswSeek(SC1->C1_USER,.t.)
					_cAprov := PswRet()[1][11]
					_cMailTo :="" 
					cAprovIni:=_cAprov                        
					nPoscAprov:=1 
					_cAprov:=Substr(cAprovIni,1,6)
					while _cAprov $ cAprovIni
					      nPoscAprov+=7
					      _cMailTo +=rtrim(UsrRetMail(_cAprov))  
					      _cAprov:=Substr(cAprovIni,nPoscAprov,6)
					      if _cAprov $ cAprovIni
					      	_cMailTo +=";" 
					      endif	   
					enddo            
										
				
					oHtml   := oProcess:oHtml                        
					oHtml:valbyname("Num"		, cNumSc1)
			        oHtml:valbyname("Req"    	, Req)
				    oHtml:valbyname("Emissao"   , SC1->C1_EMISSAO)
				    oHtml:valbyname("Motivo"   , cMotivo)
				
					cQuery2 := " SELECT C1_ITEM, C1_PRODUTO, C1_DESCRI "
					cQuery2 += " FROM "+RetSqlName('SC1')+" SC1"
					cQuery2 += " WHERE C1_NUM = '"+cNumSc1+"' AND C1_FILIAL = '" + XFILIAL("SC1") + "' AND SC1.D_E_L_E_T_ = ' ' "
					
					dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQuery2),"TRB", .F., .T.)
				
					If !TRB->(EOF())
					
						dbSelectArea("TRB")
						dbGoTop()   
						While !EOF()
							aadd(oHtml:ValByName("it.Item")		, TRB->C1_ITEM)
							aadd(oHtml:ValByName("it.Cod")		, TRB->C1_PRODUTO)
							aadd(oHtml:ValByName("it.Desc")		, TRB->C1_DESCRI)
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
					IF SC1->C1_APROV=="R"
						oProcess:cSubject := "A SOLICITACAO "+SC1->C1_NUM+" JA FOI REPROVADA PELO APROVADOR "+UPPER(Alltrim(Req))+"."
					Else 
						oProcess:cSubject := "A SOLICITACAO "+SC1->C1_NUM+" JA FOI APROVADA PELO APROVADOR "+UPPER(Alltrim(Req))+"."
					EndIf	
					oProcess:cBody    := ""
					oProcess:bReturn  := ""
					oProcess:Start()
				
					oProcess:Free()
					oProcess:Finish()
					oProcess:= Nil                  
					//WFSendMail({cEmpAnt,cFilAnt})
	
	Endif
Return(lRet)
