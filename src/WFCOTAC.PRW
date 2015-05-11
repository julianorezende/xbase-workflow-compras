#include "rwmake.ch"
#include "TbiConn.ch"
#include "TbiCode.ch"

*------------------------------------------------------------------------------------------------------------------------------------*
* Fonte      * MT130WF * Autor  * CONSULTORIA ON LINE   * Benedic, Domine Deus, in hac societate quae facit.	Data *  16/04/2014	 *
*------------------------------------------------------------------------------------------------------------------------------------*
* Descricão  * Ponto de entrada para enviar wokflow de cotação do fornecedor.														 *
*------------------------------------------------------------------------------------------------------------------------------------*
* Uso        * 	Renovagro	- Modulo Compras 																						 *
*------------------------------------------------------------------------------------------------------------------------------------*
* Consultor  * Juliano Rezende Ribeiro 																								 *
*------------------------------------------------------------------------------------------------------------------------------------*


User Function MT130WF(oProcess)

If !MsgYesNo("Deseja enviar e-mail de cotação para os Fornecedores?")
   Return
Endif 
MsgRun("Enviando Workflow Cotação de Compras, Aguarde...","",{|| CursorWait(), MT130WFi( oProcess ),CursorArrow()})

Return                        

*------------------------------------------------------------------------------------------------------------------------------------*
* Fonte      * MT130WFi * Autor  * CONSULTORIA ON LINE   * Benedic, Domine Deus, in hac societate quae facit.	Data *  16/04/2014	 *
*------------------------------------------------------------------------------------------------------------------------------------*
* Descricão  * Ponto de entrada para enviar wokflow de cotação do fornecedor.															 *
*------------------------------------------------------------------------------------------------------------------------------------*
* Uso        * 	Renovagro	- Modulo Compras 																						 *
*------------------------------------------------------------------------------------------------------------------------------------*
* Consultor  * Juliano Rezende Ribeiro 																								 *
*------------------------------------------------------------------------------------------------------------------------------------*


Static Function MT130WFi(OProcess) 

Local aCond:={}, aFrete:= {}, aSubst:={}, nTotal := 0
Local _cC8_NUM, _cC8_FORNECE, _cC8_LOJA
Local _cEmlFor
Local cEmail  	:= Space(30)
Local cUsermail


//atualiza quando nao for rotina automatica do configurador
If len(PswRet()) # 0
	cUsermail := PswRet()[1][14]
EndIF

dbSelectArea("SC8")
dbSetOrder(1)
dbSeek(xFilial("SC8")+ParamIXB[1])
while !eof() .and. xFilial("SC8")+ParamIXB[1]==SC8->C8_FILIAL+SC8->C8_NUM
	//caso ja tenha sido respondida
	If SC8->C8_WFCO == "100004"
		SC8->(dbSkip())
		Loop
	EndIF
	
	_cC8_NUM     := SC8->C8_NUM
	_cC8_FORNECE := SC8->C8_FORNECE
	_cC8_LOJA    := SC8->C8_LOJA
	
//		while !eof() .and. SC8->C8_FILIAL = xFilial("SC8") .and. SC8->C8_NUM = _cC8_NUM .and. SC8->C8_FORNECE = _cC8_FORNECE 	.and. SC8->C8_LOJA  = _cC8_LOJA
// sem 	
	
			// Tabela de Fornecedores
			dbSelectArea('SA2')
			dbSetOrder(1)
			dbSeek( xFilial('SA2') + _cC8_FORNECE + _cC8_LOJA )
			_cEmlFor := SA2->A2_EMAIL
			//caso nao encontre um e-mail
			If Empty(_cEmlFor)
				If MsgYesNo("O Fornecedor "+SA2->A2_COD+"-"+SA2->A2_NOME+" nao tem um email cadsatrado, deseja cadastrar agora?")
					
					@ 100,153 To 329,435 Dialog oDlg Title OemToAnsi("Endereco de e-mail")
					@ 9,9 Say OemToAnsi("E-mail") Size 99,8
					@ 28,9 Get cEmail  Size 79,10
					
					@ 62,39 BMPBUTTON TYPE 1 ACTION Close(oDlg)
					
					Activate Dialog oDlg Centered
					//grava o email no SA2
					RecLock("SA2",.F.)
					A2_EMAIL = cEmail
					MsUnlock()
					_cEmlFor := cEmail
				EndIf
			EndIf
			
			//Faz nova verificacao do e-mail
			if Alltrim(_cEmlFor) <> " "
				
				oProcess := TWFProcess():New( "PEDCOM", "Cotacao de Precos" )
				oProcess :NewTask( "Fluxo de Compras", "\workflow\htm\cotacao.htm" )
				oHtml    := oProcess:oHTML
				
				// Cotacoes
				dbSelectArea('SC8')
				dbSetOrder(1)
				dbSeek( xFilial('SC8') + _cC8_NUM + _cC8_FORNECE + _cC8_LOJA )
				oHtml:ValByName( "C8_CONTATO" , SC8->C8_CONTATO  )
				
				//armazena dados do usuario
				PswOrder(1)
				if PswSeek(cUsuario,.t.)
					aInfo    := PswRet(1)
					_cUser   := aInfo[1,2]
				endIf
				
		//		/ Preenche os dados do cabecalho /
				oHtml:ValByName( "C8_NUM"    , SC8->C8_NUM     )
				oHtml:ValByName( "C8_VALIDA" , SC8->C8_VALIDA  )
				oHtml:ValByName( "C8_FORNECE", SC8->C8_FORNECE )
				oHtml:ValByName( "C8_LOJA"   , SC8->C8_LOJA    )
				
				// Tabela de Fornecedores
				dbSelectArea('SA2')
				dbSetOrder(1)
				dbSeek( xFilial('SA2') + _cC8_FORNECE + _cC8_LOJA )
				oHtml:ValByName( "A2_NOME"   , SA2->A2_NOME   )
				oHtml:ValByName( "A2_END"    , SA2->A2_END    )
				oHtml:ValByName( "A2_MUN"    , SA2->A2_MUN    )
				oHtml:ValByName( "A2_BAIRRO" , SA2->A2_BAIRRO )
				oHtml:ValByName( "A2_TEL"    , SA2->A2_TEL    )
				oHtml:ValByName( "A2_FAX"    , SA2->A2_FAX    )
				
				//natureza
				dbSelectArea("SE4")
				dbSetOrder(1)
				if dbSeek(xFilial("SE4") + SA2->A2_COND )
					aAdd( aCond, SE4->E4_Codigo + " - " + SE4->E4_Descri )
				endif
				dbGoTop()
				while !eof() .and. SE4->E4_Filial == xFilial("SE4")
					aAdd( aCond, SE4->E4_Codigo + " - " + SE4->E4_Descri )
					dbSkip()
				enddo
				
				// Cotacoes
				dbSelectArea('SC8')
				dbSetOrder(1)
				dbSeek( xFilial('SC8') + _cC8_NUM + _cC8_FORNECE + _cC8_LOJA )
				oHtml:ValByName( "C8_CONTATO" , SC8->C8_CONTATO  )
				//busca os itens
				while !eof() .and. SC8->C8_FILIAL = xFilial("SC8") .and. SC8->C8_NUM     = _cC8_NUM .and. SC8->C8_FORNECE = _cC8_FORNECE 	.and. SC8->C8_LOJA    = _cC8_LOJA
					
					aAdd( (oHtml:ValByName( "it.item"    )), SC8->C8_ITEM    )
					aAdd( (oHtml:ValByName( "it.produto" )), SC8->C8_PRODUTO )
					
					dbSelectArea("SB1")
					dbSetOrder(1)
					dbSeek(xFilial("SB1") + SC8->C8_PRODUTO )
					aAdd( (oHtml:ValByName( "it.descri"  )), SB1->B1_DESC    )
					aAdd( (oHtml:ValByName( "it.quant"   )), TRANSFORM( SC8->C8_QUANT,'@E 99,999.99' ) )
					aAdd( (oHtml:ValByName( "it.um"      )), SC8->C8_UM      )
					aAdd( (oHtml:ValByName( "it.preco"   )), TRANSFORM( 0.00,'@E 99,999.99' ) )
					aAdd( (oHtml:ValByName( "it.valor"   )), TRANSFORM( 0.00,'@E 99,999.99' ) )
					aAdd( (oHtml:ValByName( "it.prazo"   )), " ")
					aAdd( (oHtml:ValByName( "it.ipi"     )), TRANSFORM( 0.00,'@E 99,999.99' ) )
		//			aAdd( (oHtml:ValByName( "it.dia"     )), str(day(SC8->C8_DATPRF))         )
		//			aAdd( (oHtml:ValByName( "it.mes"     )), padl( alltrim( str( month(SC8->C8_DATPRF) ) ),2,"0") )
		//			aAdd( (oHtml:ValByName( "it.ano"     )), right(str(year(SC8->C8_DATPRF)),2))
					dbSelectArea("SC8")
					//GRAVA DADOS NO SC8
					RecLock('SC8')
					C8_WFCO   := "100003"
					If Empty(C8_WFDT)
						C8_WFDT   := dDataBase
					EndIF
					If Empty(C8_WFEMAIL)
						If cUsername == "Administrador"
							C8_WFEMAIL := GetMV("MV_RELACNT")
						Else
							C8_WFEMAIL := cUsermail
						EndIF
					EndIf
					C8_WFID := oProcess:fProcessID
					MsUnlock()
					dbSkip()
				enddo
				
				Msginfo("E-mail de cotação enviado para: "+_cEmlFor)
				oHtml:ValByName( "Pagamento", aCond    )
				oHtml:ValByName( "Frete"    , {"CIF","FOB"}   )
				oHtml:ValByName( "subtot"   , TRANSFORM( 0 ,'@E 999,999.99' ) )
				oHtml:ValByName( "vldesc"   , TRANSFORM( 0 ,'@E 999,999.99' ) )
				oHtml:ValByName( "aliipi"   , TRANSFORM( 0 ,'@E 999,999.99' ) )
		//		oHtml:ValByName( "Valipi"   , TRANSFORM( 0 ,'@E 999,999.99' ) )
				oHtml:ValByName( "valfre"   , TRANSFORM( 0 ,'@E 999,999.99' ) )
				oHtml:ValByName( "totped"   , TRANSFORM( 0 ,'@E 999,999.99' ) )
				
				oProcess:cSubject := "Processo de geracao de Cotacao de Precos " + _cC8_NUM
				oProcess:cTo      := _cEmlFor
		//		oProcess:bReturn  := "U_MT130WFR(1)"
				//		oProcess:bTimeOut := { { "U_MT130WF(6)", 1, 1, 10 } } //oProcess:bTimeOut := { { funcao, dias, horas, minutos0 } }
				oProcess:Start()
				
				//RastreiaWF( ID do Processo, Codigo do Processo, Codigo do Status, Descricao Especifica, Usuario )
				RastreiaWF(oProcess:fProcessID+'.'+oProcess:fTaskID,"PEDCOM",'100003',"Email Enviado Para o Fornecedor:"+SA2->A2_NOME,RetCodUsr())
				//WFSendMail()
			else
				// Atualizar SC8 para nao processar novamente
				dbSelectArea("SC8")
				RecLock('SC8')
				SC8->C8_WFID := "WF9999"
				MsUnlock()
				dbSkip()
			endif
  //		EndDo
enddo

Return

*------------------------------------------------------------------------------------------------------------------------------------*
* Fonte      * MT130WFr * Autor  * CONSULTORIA ON LINE   * Benedic, Domine Deus, in hac societate quae facit.	Data *  16/04/2014	 *
*------------------------------------------------------------------------------------------------------------------------------------*
* Descricão  * Ponto de entrada para enviar wokflow de cotação do fornecedor.															 *
*------------------------------------------------------------------------------------------------------------------------------------*
* Uso        * 	Renovagro	- Modulo Compras 																						 *
*------------------------------------------------------------------------------------------------------------------------------------*
* Consultor  * Juliano Rezende Ribeiro 																								 *
*------------------------------------------------------------------------------------------------------------------------------------*


User Function MT130WFr(AOpcao, oProcess) //MT130WFR
Local aCab   :={}
Local aItem  := {}
Local nUsado := 0
Local aRelImp := MaFisRelImp("MT150",{"SC8"})
Local nY,_nind

if ValType(aOpcao) = "A"
	aOpcao := aOpcao[1]
endif

if aOpcao == NIL
	aOpcao := 0
endIf

if aOpcao == 1
	_cC8_NUM     := oProcess:oHtml:RetByName("C8_NUM"     )
	_cC8_FORNECE := oProcess:oHtml:RetByName("C8_FORNECE" )
	_cC8_LOJA    := oProcess:oHtml:RetByName("C8_LOJA"    )
    cEmpresa     := oProcess:oHtml:RetByname("WFEMPRESA")
    cFilial      := oProcess:oHtml:RetByname("WFFILIAL")
endif

ConOut("Retorno da Cotacao: Empresa:"+cEmpresa+" / Filial: "+cFilial+" / "+_cC8_NUM)

If cEmpresa+cFilial <> AllTrim(cEmpAnt+cFilAnt)
	
	RESET ENVIRONMENT 
	RpcSetType( 3 )
	PREPARE ENVIRONMENT EMPRESA cEmpresa FILIAL cFilial MODULO "COM"
	RpcSetEnv( cEmpresa, cFilial,,,"COM")
	
EndIf

dbSelectArea("SC8")
dbSetOrder(1)
dbSeek( xFilial("SC8") + Padr(_cC8_NUM,6) + Padr(_cC8_FORNECE,6) + _cC8_LOJA )
If Found()
	ConOut("ENCONTRADO - Retorno da Cotacao: Empresa:"+cEmpresa+" / Filial: "+cFilial+" / "+_cC8_NUM)
Else
	ConOut("NAO ENCONTRADO - Retorno da Cotacao: Empresa:"+cEmpresa+" / Filial: "+cFilial+" / "+_cC8_NUM)
Endif
// Cotacao Recebida
if oProcess:oHtml:RetByName("Aprovacao") = "S"
	
	RastreiaWF(oProcess:fProcessID+'.'+oProcess:fTaskID,"PEDCOM",'100004',"Email respondido pelo Fornecedor:"+_cC8_FORNECE,RetCodUsr())
	_cC8_VLDESC := oProcess:oHtml:RetByName("VLDESC" )
	_cC8_ALIIPI := oProcess:oHtml:RetByName("ALIIPI" )
	_cC8_VALFRE := oProcess:oHtml:RetByName("VALFRE" )
	
	//verifica o frete
	if oProcess:oHtml:RetByName("Frete") = "FOB"
		_cC8_RATFRE := 0
	endif
	
	//grava no SC8
	for _nind := 1 to len(oProcess:oHtml:RetByName("it.preco"))
		//BASE DO ICMS
		MaFisIni(Padr(_cC8_FORNECE,6),_cC8_LOJA,"F","N","R",aRelImp)
		MaFisIniLoad(1)
		For nY := 1 To Len(aRelImp)
			MaFisLoad(aRelImp[nY][3],SC8->(FieldGet(FieldPos(aRelImp[nY][2]))),1)
		Next nY
		MaFisEndLoad(1)
		
		dbSelectArea("SB1")
		dbSetOrder(1)
		dbSeek( xFilial() + oProcess:oHtml:RetByName("it.produto")[_nind] )
		cIcm := SC8->C8_PICM
		
		_cC8_ITEM := oProcess:oHtml:RetByName("it.item")[_nind]
		dbSelectArea("SC8")
		dbSetOrder(1)
		dbSeek( xFilial("SC8") + Padr(_cC8_NUM,6) + Padr(_cC8_FORNECE,6) + _cC8_LOJA + _cC8_ITEM )
		//caso o prazo tenha vencido nï¿½o permite gravacao
		If C8_WFID = "9999"
			Return
		EndIf
		RecLock("SC8",.f.)
		SC8->C8_WFCO   := "100004"
		SC8->C8_PRECO  := Val(oProcess:oHtml:RetByName("it.preco")[_nind])
		SC8->C8_TOTAL  := Val(oProcess:oHtml:RetByName("it.valor")[_nind])
		SC8->C8_ALIIPI := Val(oProcess:oHtml:RetByName("it.ipi"  )[_nind])
		//caso o IPI nï¿½o seja zero
		If Val(oProcess:oHtml:RetByName("it.ipi"  )[_nind])>0
			C8_VALIPI  := (Val(oProcess:oHtml:RetByName("it.ipi"  )[_nind])*Val(oProcess:oHtml:RetByName("it.valor")[_nind]))/100
			C8_BASEIPI := SC8->C8_TOTAL
		EndIf
		SC8->C8_PRAZO  := Val(oProcess:oHtml:RetByName("it.prazo")[_nind])
		//caso o icm nao seja zero
		MaFisAlt("IT_ALIQICM",cIcm,1)
		C8_PICM        := MaFisRet(1,"IT_ALIQICM")
		
		If C8_PICM >0
			C8_BASEICM     := SC8->C8_TOTAL
			MaFisAlt("IT_VALICM",cIcm,1)
			C8_VALICM      := MaFisRet(1,"IT_VALICM")
		EndIf
//		_C8_DATPRF     :=     oProcess:oHtml:RetByName("it.dia"  )[_nind] + "/" + ;
//		oProcess:oHtml:RetByName("it.mes"  )[_nind] + "/" + ;
//		oProcess:oHtml:RetByName("it.ano"  )[_nind]
		//		SC8->C8_DATPRF := CTOD(_C8_DATPRF)
		SC8->C8_COND   := Substr(oProcess:oHtml:RetByName("pagamento"),1,3)
		SC8->C8_TPFRETE:= Substr(oProcess:oHtml:RetByName("Frete"),1,1)
		
		iif( oProcess:oHtml:RetByName("Frete") = "FOB", ;
		SC8->C8_VALFRE := 0, ;
		SC8->C8_VALFRE := Val(oProcess:oHtml:RetByName("it.quant")[_nind]) * ;
		Val(oProcess:oHtml:RetByName("it.preco")[_nind]) / ;
		Val(oProcess:oHtml:RetByName("totped") ) *         ;
		Val(oProcess:oHtml:RetByName("valfre") ) )
		
		iif( Val(oProcess:oHtml:RetByName("vldesc")) == 0 ,;
		SC8->C8_VLDESC := 0, ;
		SC8->C8_VLDESC := Val(oProcess:oHtml:RetByName("it.quant")[_nind]) * ;
		Val(oProcess:oHtml:RetByName("it.preco")[_nind]) / ;
		Val(oProcess:oHtml:RetByName("totped") ) * ;
		Val(oProcess:oHtml:RetByName("vldesc") ) )
		
		MsUnlock()
		MaFisEnd()
	next
	
Else //caso tenha sido rejeitado
	
	
	aCab := {	{"C8_NUM"	,_cC8_NUM,NIL}}
	
	//ATUALIZA O SC8
	for _nind := 1 to len(oProcess:oHtml:RetByName("it.preco"))
		
		_cC8_ITEM := oProcess:oHtml:RetByName("it.item")[_nind]
		//PEGA O EMAIL PARA AVISAR O COMPRADOR
		dbSelectArea("SC8")
		dbSetOrder(1)
		dbSeek( xFilial("SC8") + Padr(_cC8_NUM,6) + Padr(_cC8_FORNECE,6) + _cC8_LOJA + _cC8_ITEM )
		//caso o prazo tenha vencido nï¿½o permite gravacao
		If C8_WFCO = "999999"
			Return
		EndIf
		cEmailComp := C8_WFEMAIL
		
		lMsErroAuto := .F.
		
		aadd(aItem,   {{"C8_ITEM",_cC8_ITEM ,NIL},;
		{"C8_FORNECE",_cC8_FORNECE ,NIL},;
		{"C8_LOJA",_cC8_LOJA ,NIL}})
		
		MSExecAuto({|x,y,z| mata150(x,y,z)},aCab,aItem,5) //EXCLUI
		
		If lMsErroAuto
			Alert("Erro")
		Else
			Alert("Ok")
		Endif
		
		
	Next
	Reprovar(oProcess,cEmailComp)
	
endif
Return

*------------------------------------------------------------------------------------------------------------------------------------*
* Fonte      * REPROVAR * Autor  * CONSULTORIA ON LINE   * Benedic, Domine Deus, in hac societate quae facit.	Data *  16/04/2014	 *
*------------------------------------------------------------------------------------------------------------------------------------*
* Descricão  * Ponto de entrada para enviar wokflow de cotação do fornecedor.															 *
*------------------------------------------------------------------------------------------------------------------------------------*
* Uso        * 	Renovagro	- Modulo Compras 																						 *
*------------------------------------------------------------------------------------------------------------------------------------*
* Consultor  * Juliano Rezende Ribeiro 																								 *
*------------------------------------------------------------------------------------------------------------------------------------*


static function Reprovar(oProcess,cEmailComp)

_user := Subs(cUsuario,7,15)
oProcess:ClientName(_user)
oProcess:cTo      := cEmailComp
oProcess:cCC      := ""
oProcess:cBCC     := ""
oProcess:cSubject := "Desistencia do Fornecedor"

oProcess:cBody    := ""
oProcess:bReturn  := ""
oProcess:bTimeOut := ""

oProcess:Start()
oProcess:Finish()

//WFSendMail()
return                                                                      



//#include "rwmake.ch"
//#include "TbiConn.ch"
//#include "TbiCode.ch"

*------------------------------------------------------------------------------------------------------------------------------------*
* Fonte      * RETWFSC8 * Autor  * CONSULTORIA ON LINE   * Benedic, Domine Deus, in hac societate quae facit.	Data *  16/04/2014	 *
*------------------------------------------------------------------------------------------------------------------------------------*
* Descricão  * Ponto de entrada para enviar wokflow de cotação do fornecedor.															 *
*------------------------------------------------------------------------------------------------------------------------------------*
* Uso        * 	Renovagro	- Modulo Compras 																						 *
*------------------------------------------------------------------------------------------------------------------------------------*
* Consultor  * Juliano Rezende Ribeiro 																								 *
*------------------------------------------------------------------------------------------------------------------------------------*


User Function Retwfsc8(__aCookies,__aPostParms,__nProcID,__aProcParms,__cHTTPPage)

	Local aCab   :={}
	Local aItem  := {}
	//Local nUsado := 0
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
		
							//caso o prazo tenha vencido nï¿½o permite gravacao
							If SC8->C8_VALIDA < dDatabase
								//Envio WF avisando que o Fornecedor foi desclassificado
								Private cMailBox := AllTrim(WFGetMV( "MV_WFMLBOX", "" ))
								Private cTo      := AllTrim(SA2->A2_EMAIL)
								Private oMail    := TWFMail():New()
								Private oMailBox := oMail:GetMailBox( cMailBox )
				
								Private cHtml    := ""
								Private cSubject := "Desclassificação por Data - Cotação "+SC8->C8_NUM
								Private cBody    := "Desclassificação por Data - Cotação "+SC8->C8_NUM
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
		
							//caso o IPI nï¿½o seja zero
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
								//caso o prazo tenha vencido nï¿½o permite gravacao
								If SC8->C8_VALIDA < dDatabase
									//Envio WF avisando que o Fornecedor foi desclassificado
											cMailBox := AllTrim(WFGetMV( "MV_WFMLBOX", "" ))
											cTo      := AllTrim(SA2->A2_EMAIL)
											oMail    := TWFMail():New()
											oMailBox := oMail:GetMailBox( cMailBox )
					
								    cHtml    := ""
											cSubject := "Desclassificação por Data - Cotação "+SC8->C8_NUM
											cBody    := "Desclassificação por Data - Cotação "+SC8->C8_NUM
									aAttachs := {}
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
									ConOut("Erro na Exclusão do Participante, Fornecedor: "+SC8->(C8_FORNECE+C8_LOJA)+" Cotacao: "+SC8->C8_NUM)
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
					cMailBox := AllTrim(WFGetMV( "MV_WFMLBOX", "" ))
					cTo      := AllTrim(cEmailComp)
					oMail    := TWFMail():New()
					oMailBox := oMail:GetMailBox( cMailBox )

					cHtml    := ""
					cSubject := "Desistencia do processo de cotação do Fornecedor "+SC8->C8_FORNECE+" - " + Posicione("SA2",1,XFILIAL("SA2")+SC8->(C8_FORNECE+C8_LOJA),"A2_NOME")
					cBody    := cSubject
			aAttachs := {}
			oMailBox:NewMessage( cTo,,, cSubject, cBody, aAttachs )
			oMailBox:Send() //Enviando email
			
		endif
		
	Else

		ConOut("NAO ENCONTRADO - Retorno da Cotacao: Empresa:"+cEmpresa+" / Filial: "+cFil_+" / "+cNumSc8)

	Endif
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ O arquivo texto deve ser fechado, bem como o dialogo criado na fun- ³
	//³ cao anterior.                                                       ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	

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