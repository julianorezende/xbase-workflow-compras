#include "rwmake.ch"
#include "TbiConn.ch"
#include "TbiCode.ch"

*------------------------------------------------------------------------------------------------------------------------------------*
* Fonte      * COMRD001 * Autor  * CONSULTORIA ON LINE   * Benedic, Domine Deus, in hac societate quae facit.	Data *  16/04/2014	 *
*------------------------------------------------------------------------------------------------------------------------------------*
* Descricão  * Envia WorkFlow de Aprovacao de Solicitacao de Compras																 *
*------------------------------------------------------------------------------------------------------------------------------------*
* Uso        * 	Renovagro	- Modulo Compras 																						 *
*------------------------------------------------------------------------------------------------------------------------------------*
* Consultor  * Juliano Rezende Ribeiro 																								 *
*------------------------------------------------------------------------------------------------------------------------------------*
* Criar Campo *   Nome	    Tipo	Tamanho 	Titulo	         OBS																 *
*             * C1_CODAPRO   C         6        Cod Aprovador																		 * 
*------------------------------------------------------------------------------------------------------------------------------------*


User Function COMRD001()

Local   cSuperior:=_InfoUSR(__CUSERID )
//Local   cTotItem  := Strzero(Len(aCols),4)
Local _i
Private cDiasA
Private cDiasE  

//msgalert('teste')

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿    
//³Verifica a Existencia de Parametro MV__TIMESC³
//³Caso nao exista. Cria o parametro.           ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
dbSelectArea("SX6")
If ! dbSeek("  "+"MV__TIMESC")   
	RecLock("SX6",.T.)
	X6_VAR    	:= "MV__TIMESC"
	X6_TIPO 	:= "C"
	X6_CONTEUD 	:= "0305"            
	X6_CONTENG 	:= "0305"
	X6_CONTSPA 	:= "0305"
	X6_DESCRIC	:= "DEFINE TEMPO EM DIAS DE TIMEOUT DA APROVACAO DE SO"
	X6_DESC1	:= "LICITACAO DE COMPRAS - EX: AVISO EM 3 DIAS E EXCLU"
	X6_DESC2	:= "SAO EM 5 DIAS = 0305                              "
	MsUnlock("SX6")
EndIf

cDiasA := SubStr(GetMv("MV__TIMESC"),1,2) //TIMEOUT Dias para Avisar Aprovador
cDiasE := SubStr(GetMv("MV__TIMESC"),3,2) //TIMEOUT Dias para Excluir a Solicitacao

Pergunte("COMRD1",.F.) //Carrega Perguntas

If !Empty(cSuperior)
	for _i:= 1 to Len(aCols)
		RecLock("SC1",.F.)
		C1_CODAPRO := cSuperior
		MsUnlock()     
	Next

	/*	-- Comentado esse bloco para nao enviar mais o detalhes da Solicitacao porque esta trazendo o valor de custo errado, devido
	    as informacoes na base de dados estarem erradas  

			If mv_par04 == 1 //Aprovacao por ITEM
				U_COMWF002()
		      ElseIf SC1->C1_ITEM == cTotItem //Aprovacao por SOLICITACAO
				U_COMWF001()
			EndIf
	*/
//	U_COMWF002() //Envio dos Detalhes da Solicitacao
	
//	If SC1->C1_ITEM == cTotItem
	U_COMWF001(cSuperior) //Envido do Resumo da Solicitacao
//	EndIf
	
EndIf

Return(.T.)



*------------------------------------------------------------------------------------------------------------------------------------*
* Fonte      * COMWF001 * Autor  * CONSULTORIA ON LINE   * Benedic, Domine Deus, in hac societate quae facit.	Data *  16/04/2014	 *
*------------------------------------------------------------------------------------------------------------------------------------*
* Descricão  * Envia WorkFlow de Aprovacao de Solicitacao de Compras quando a aprovacao e feita por solicitacao.					 *
*------------------------------------------------------------------------------------------------------------------------------------*
* Uso        * 	Renovagro	- Modulo Compras 																						 *
*------------------------------------------------------------------------------------------------------------------------------------*
* Consultor  * Juliano Rezende Ribeiro 																								 *
*------------------------------------------------------------------------------------------------------------------------------------*

User Function COMWF001(cAprov)

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Declaração de Variaveis³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
Local cMvAtt := GetMv("MV_WFHTML")
Local cMailSup :="" 
Private oHtml
cAprov := PswRet()[1][11]
cAprovIni:=cAprov                        
nPoscAprov:=1 
cAprov:=Substr(cAprovIni,1,6)
while cAprov $ cAprovIni
      nPoscAprov+=7
      cMailSup +=rtrim(UsrRetMail(cAprov))  
      cAprov:=Substr(cAprovIni,nPoscAprov,6)
      if cAprov $ cAprovIni
      	cMailSup +=";" 
      endif	   
enddo            

cQuery := " SELECT C1_NUM, C1_EMISSAO, C1_SOLICIT, C1_ITEM, C1_PRODUTO, C1_DESCRI, C1_UM, C1_QUANT, C1_DATPRF, C1_OBS, C1_CC, C1_CODAPRO, C1_USER"
cQuery += " FROM "+RetSqlName('SC1')+" SC1"
cQuery += " WHERE C1_NUM = '"+SC1->C1_NUM+"' AND C1_FILIAL = '" + XFILIAL("SC1") + "' AND SC1.D_E_L_E_T_ = ' ' "

dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQuery),"TRB", .F., .T.)

TcSetField("TRB","C1_EMISSAO","D")
TcSetField("TRB","C1_DATPRF","D")

dbSelectArea("TRB")
dbGoTop()

If !TRB->(EOF())     

	cNumSc		:= TRB->C1_NUM
    cSolicit    := Subs(cUsuario,7,15)
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Muda o parametro para enviar no corpo do e-mail³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	PutMv("MV_WFHTML","T")
	
	oProcess:=TWFProcess():New("PEDCOM","WORKFLOW PARA APROVACAO DE SC")
	oProcess:NewTask('Inicio',"\workflow\htm\comwf001.htm")
	oHtml   := oProcess:oHtml
	
	oHtml:ValByName("diasA"			, cDiasA)
	oHtml:ValByName("diasE"			, cDiasE)
	oHtml:ValByName("cNUM"			, TRB->C1_NUM)
	oHtml:ValByName("cEMISSAO"		, DTOC(TRB->C1_EMISSAO))
	oHtml:ValByName("cSOLICIT"		, cSolicit)
	oHtml:ValByName("cCODUSR"		, RetCodUsr(cSolicit))
	oHtml:ValByName("cAPROV"		, "")
	oHtml:ValByName("cMOTIVO"		, "")
	oHtml:ValByName("it.ITEM"		, {})
	oHtml:ValByName("it.PRODUTO"	, {})
	oHtml:ValByName("it.DESCRI"		, {})
	oHtml:ValByName("it.UM"			, {})
	oHtml:ValByName("it.QUANT"		, {})
	oHtml:ValByName("it.DATPRF"		, {})
	oHtml:ValByName("it.OBS"		, {})
	oHtml:ValByName("it.CC"			, {})
	
	While !TRB->(EOF())
		aadd(oHtml:ValByName("it.ITEM")       ,TRB->C1_ITEM			) //Item Cotacao
		aadd(oHtml:ValByName("it.PRODUTO")    ,TRB->C1_PRODUTO		) //Cod Produto
		aadd(oHtml:ValByName("it.DESCRI")     ,TRB->C1_DESCRI		) //Descricao Produto
		aadd(oHtml:ValByName("it.UM")         ,TRB->C1_UM			) //Unidade Medida
		aadd(oHtml:ValByName("it.QUANT")      ,TRANSFORM( TRB->C1_QUANT,'@E 999,999,999.99' )) //Quantidade Solicitada
		aadd(oHtml:ValByName("it.DATPRF")     ,DTOC(TRB->C1_DATPRF)) //Data da Necessidade
		aadd(oHtml:ValByName("it.OBS")        ,TRB->C1_OBS			) //Observacao
		aadd(oHtml:ValByName("it.CC")         ,TRB->C1_CC			) //Centro de Custo
		TRB->(dbSkip())
	End
	
	//envia o e-mail
	Msginfo("E-mail de aprovação da SC enviado para: "+cMailSup)
	cUser 				:= Subs(cUsuario,7,15)
	oProcess:ClientName(cUser)
	oProcess:cTo    	:= cMailSup
	oProcess:cSubject  	:= "Aprovação de SC - "+cNumSc+" - De: "+cSolicit
	oProcess:cBody    	:= ""
    //oProcess:bReturn  := "Retwfsc1()"
	//oProcess:bTimeOut := {{"U_COMWF01b()", 0 , 0, 3 },{"U_COMWF01c()", 0 , 0, 6 }}
	//oProcess:bTimeOut   := {{"U_COMWF01b()", Val(cDiasA) , 0, 0 },{"U_COMWF01c()", Val(cDiasE) , 0, 0 }}
	oProcess:Start()
	//RastreiaWF( ID do Processo, Codigo do Processo, Codigo do Status, Descricao Especifica, Usuario )
	RastreiaWF(oProcess:fProcessID+'.'+oProcess:fTaskID,"PEDCOM","100100","ENVIO DE WORKFLOW PARA APROVACAO DE SC",cUsername)
	oProcess:Free()
	oProcess:= Nil
	
	PutMv("MV_WFHTML",cMvAtt)
	
	TRB->(dbCloseArea())
	
	//WFSendMail({cEmpant,cFilant})

Else                                    // 1 IF 
	TRB->(dbCloseArea())
	MsgStop("Problemas no Envio do E-Mail de Aprovação!","ATENÇÃO!")
EndIf
Return()



*------------------------------------------------------------------------------------------------------------------------------------*
* Fonte      * COMWF01a * Autor  * CONSULTORIA ON LINE   * Benedic, Domine Deus, in hac societate quae facit.	Data *  16/04/2014	 *
*------------------------------------------------------------------------------------------------------------------------------------*
* Descricão  * Retor Workflow de Aprovacao de Solicitacao de Compras																 *
*------------------------------------------------------------------------------------------------------------------------------------*
* Uso        * 	Renovagro	- Modulo Compras 																						 *
*------------------------------------------------------------------------------------------------------------------------------------*
* Consultor  * Juliano Rezende Ribeiro 																								 *
*------------------------------------------------------------------------------------------------------------------------------------*

User Function COMWF01a(oProcess)

Local cMvAtt := GetMv("MV_WFHTML")
Local cNumSc	:= oProcess:oHtml:RetByName("cNUM")
Local cSolicit	:= oProcess:oHtml:RetByName("cSOLICIT")
Local cEmissao	:= oProcess:oHtml:RetByName("cEMISSAO")
Local cAprov	:= oProcess:oHtml:RetByName("cAPROV")
Local cMotivo	:= oProcess:oHtml:RetByName("cMOTIVO")
Local cCodSol	:= oProcess:oHtml:RetByName("cCODUSR")
Local cEmpresa  := oProcess:oHtml:RetByname("WFEMPRESA")
Local cFilial   := oProcess:oHtml:RetByname("WFFILIAL")
Local cMailSol 	:= UsrRetMail(cCodSol)
//Local cMailSup  := UsrRetMail(cAprov)
Private oHtml

ConOut("Retorno da SC: Empresa:"+cEmpresa+" / Filial: "+cFilial+" / "+cNumSc)

cFilAnt:=	cFilial
cEmpAnt:=	cEmpresa
                   

If cEmpresa+cFilial <> AllTrim(cEmpAnt+cFilAnt)
	
	RESET ENVIRONMENT 
	RpcSetType( 3 )
	PREPARE ENVIRONMENT EMPRESA cEmpresa FILIAL cFilial MODULO "COM"
	RpcSetEnv( cEmpresa, cFilial,,,"COM")
	
EndIf

DBSELECTAREA("SM0")
DBSEEK(cEmpresa+cFilial)

cQuery := " UPDATE "+RETSQLNAME("SC1")                                
cQuery += " SET C1_APROV = '"+cAprov+"'"
cQuery += " WHERE C1_NUM = '"+cNumSC+"'  AND C1_FILIAL = '" + XFILIAL("SC1") + "' AND D_E_L_E_T_ = ' ' "

TcSqlExec(cQuery)
TCREFRESH(RetSqlName("SC1"))


//RastreiaWF( ID do Processo, Codigo do Processo, Codigo do Status, Descricao Especifica, Usuario )
RastreiaWF(oProcess:fProcessID+'.'+oProcess:fTaskID,"PEDCOM",'100200',"RETORNO DE WORKFLOW PARA APROVACAO DE SC",cUsername)

oProcess:Finish()
oProcess:Free()
oProcess:= Nil

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Inicia Envio de Mensagem de Aviso³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
PutMv("MV_WFHTML","T")

oProcess:=TWFProcess():New("PEDCOM","WORKFLOW PARA APROVACAO DE SC")
If cAprov == "L" //Verifica se foi aprovado
	oProcess:NewTask('Inicio',"\workflow\htm\comwf005.htm")
ElseIf cAprov == "R" //Verifica se foi rejeitado
	oProcess:NewTask('Inicio',"\workflow\htm\comwf006.htm")
EndIf
oHtml   := oProcess:oHtml

oHtml:valbyname("Num"		, cNumSc)
oHtml:valbyname("Req"    	, cSolicit)
oHtml:valbyname("Emissao"   , cEmissao)
oHtml:valbyname("Motivo"   , cMotivo)
oHtml:valbyname("it.Item"   , {})
oHtml:valbyname("it.Cod"  	, {})
oHtml:valbyname("it.Desc"   , {})

cQuery2 := " SELECT C1_ITEM, C1_PRODUTO, C1_DESCRI"
cQuery2 += " FROM "+RetSqlName('SC1')+" SC1"
cQuery2 += " WHERE C1_NUM = '"+cNumSc+"' AND C1_FILIAL = '" + XFILIAL("SC1") + "' AND SC1.D_E_L_E_T_ = ' ' "

dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQuery2),"TRB", .F., .T.)

dbSelectArea("TRB")
dbGoTop()

If !TRB->(EOF())

	While !TRB->(EOF())
		aadd(oHtml:ValByName("it.Item")		, TRB->C1_ITEM)
		aadd(oHtml:ValByName("it.Cod")		, TRB->C1_PRODUTO)
		aadd(oHtml:ValByName("it.Desc")		, TRB->C1_DESCRI)
		TRB->(dbSkip())
	End
	
EndIf
TRB->(dbCloseArea())

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Funcoes para Envio do Workflow³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
//envia o e-mail 
cUser 			  := Subs(cUsuario,7,15)
oProcess:ClientName(cUser)
//oProcess:cTo	  := "juliano.ribeiro@consultoriaonline.info"
CONOUT("e-MAIL: "+cMailSol)
CONOUT("USERCOD "+cCodSol)
oProcess:cTo	  := cMailSol 

If cAprov == "L" //Verifica se foi aprovado
	oProcess:cSubject := "SC N°: "+cNumSc+" - Aprovada"
ElseIf cAprov == "R" //Verifica se foi rejeitado
	oProcess:cSubject := "SC N°: "+cNumSc+" - Reprovada"
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

PutMv("MV_WFHTML",cMvAtt)

//WFSendMail({cEmpant,cFilant})

Return

*------------------------------------------------------------------------------------------------------------------------------------*
* Fonte      * COMWF01b * Autor  * CONSULTORIA ON LINE   * Benedic, Domine Deus, in hac societate quae facit.	Data *  16/04/2014	 *
*------------------------------------------------------------------------------------------------------------------------------------*
* Descricão  * Envia um Aviso para Aprovador apos periodo de TIMEOUT																 *
*------------------------------------------------------------------------------------------------------------------------------------*
* Uso        * 	Renovagro	- Modulo Compras 																						 *
*------------------------------------------------------------------------------------------------------------------------------------*
* Consultor  * Juliano Rezende Ribeiro 																								 *
*------------------------------------------------------------------------------------------------------------------------------------*

User Function COMWF01b(oProcess)

Local cMvAtt 	:= GetMv("MV_WFHTML")
Local cNumSc	:= oProcess:oHtml:RetByName("cNUM")
Local cSolicit	:= oProcess:oHtml:RetByName("cSOLICIT")
Local cEmissao	:= oProcess:oHtml:RetByName("cEMISSAO")
Local cDiasA	:= oProcess:oHtml:RetByName("diasA")
Local cDiasE	:= oProcess:oHtml:RetByName("diasE")
Private oHtml

ConOut("AVISO POR TIMEOUT SC:"+cNumSc+" Solicitante:"+cSolicit)

oProcess:Free()
oProcess:= Nil

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Inicia Envio de Mensagem de Aviso³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
PutMv("MV_WFHTML","T")

oProcess:=TWFProcess():New("PEDCOM","WORKFLOW PARA APROVACAO DE SC")
oProcess:NewTask('Inicio',"\workflow\htm\comwf003.htm")
oHtml   := oProcess:oHtml

oHtml:valbyname("Num"		, cNumSc)
oHtml:valbyname("Req"    	, cSolicit)
oHtml:valbyname("Emissao"   , cEmissao)
oHtml:valbyname("diasA"   	, cDiasA)
oHtml:valbyname("diasE"   	, Val(cDiasE)-Val(cDiasA))
oHtml:valbyname("it.Item"   , {})
oHtml:valbyname("it.Cod"  	, {})
oHtml:valbyname("it.Desc"   , {})

cQuery := " SELECT C1_ITEM, C1_PRODUTO, C1_DESCRI, C1_CODAPRO"
cQuery += " FROM "+RetSqlName('SC1')+" SC1"
cQuery += " WHERE C1_NUM = '"+cNumSc+"' AND C1_FILIAL = '" + XFILIAL("SC1") + "' AND SC1.D_E_L_E_T_ = ' ' "

dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQuery),"TRB", .F., .T.)

dbSelectArea("TRB")
dbGoTop()

If !TRB->(EOF())

	cMailSup := UsrRetMail(TRB->C1_CODAPRO)

	While !TRB->(EOF())
		aadd(oHtml:ValByName("it.Item")		, TRB->C1_ITEM)
		aadd(oHtml:ValByName("it.Cod")		, TRB->C1_PRODUTO)
		aadd(oHtml:ValByName("it.Desc")		, TRB->C1_DESCRI)
		TRB->(dbSkip())
	End
	
EndIf
TRB->(dbCloseArea())
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Funcoes para Envio do Workflow³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

//envia o e-mail
Msginfo("E-mail de aprovação da SC enviado para: "+cMailSup)
cUser 			  := Subs(cUsuario,7,15)
oProcess:ClientName(cUser)
oProcess:cTo	  := cMailSup

oProcess:cSubject := "Aviso de TimeOut de SC N°: "+cNumSc+" - De: "+cSolicit
oProcess:cBody    := ""
oProcess:bReturn  := ""
oProcess:Start()
//RastreiaWF( ID do Processo, Codigo do Processo, Codigo do Status, Descricao Especifica, Usuario )
RastreiaWF(oProcess:fProcessID+'.'+oProcess:fTaskID,"PEDCOM",'100300',"TIMEOUT DE WORKFLOW PARA APROVACAO DE SC",cUsername)
oProcess:Free()
oProcess:Finish()
oProcess:= Nil

PutMv("MV_WFHTML",cMvAtt)

//WFSendMail({cEmpant,cFilant})


Return

*------------------------------------------------------------------------------------------------------------------------------------*
* Fonte      * COMWF01c * Autor  * CONSULTORIA ON LINE   * Benedic, Domine Deus, in hac societate quae facit.	Data *  16/04/2014	 *
*------------------------------------------------------------------------------------------------------------------------------------*
* Descricão  * Exclui a solicitacao apos um periodo de TIMEOUT																		 *
*------------------------------------------------------------------------------------------------------------------------------------*
* Uso        * 	Renovagro	- Modulo Compras 																						 *
*------------------------------------------------------------------------------------------------------------------------------------*
* Consultor  * Juliano Rezende Ribeiro 																								 *
*------------------------------------------------------------------------------------------------------------------------------------*

User Function COMWF01c(oProcess)

Local cMvAtt 	:= GetMv("MV_WFHTML")
Local cNumSc	:= oProcess:oHtml:RetByName("cNUM")
Local cSolicit	:= oProcess:oHtml:RetByName("cSOLICIT")
Local cEmissao	:= oProcess:oHtml:RetByName("cEMISSAO")
Local cDiasA	:= oProcess:oHtml:RetByName("diasA")
Local cDiasE	:= oProcess:oHtml:RetByName("diasE")
Local cCodSol	:= RetCodUsr(cSolicit)
Local cMailSol 	:= UsrRetMail(cCodSol)
Local aCab := {}
Local aItem:= {}
Private oHtml

ConOut("EXCLUSAO POR TIMEOUT SC:"+cNumSc+" Solicitante:"+cSolicit)

cQuery := " SELECT C1_ITEM, C1_PRODUTO, C1_DESCRI, C1_CODAPRO"
cQuery += " FROM "+RetSqlName('SC1')+" SC1"
cQuery += " WHERE C1_NUM = '"+cNumSc+"' AND C1_FILIAL = '" + XFILIAL("SC1") + "' AND SC1.D_E_L_E_T_ = ' ' "

dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQuery),"TRB", .F., .T.)

dbSelectArea("TRB")
dbGoTop()

If !TRB->(EOF())
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Inicia MsExecAuto da Exclusao³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	cMailSup := UsrRetMail(TRB->C1_CODAPRO)

	While !TRB->(EOF())
		lMsErroAuto := .F.
		aCab:= {		{"C1_NUM",cNumSc,NIL}}
		Aadd(aItem, {	{"C1_ITEM",TRB->C1_ITEM,NIL}})
		
		Begin Transaction
		MSExecAuto({|x,y,z| mata110(x,y,z)},aCab,aItem,5) //Exclusao
		End Transaction
		
		TRB->(dbSkip())
	End
	
	oProcess:Finish()
	oProcess:Free()
	oProcess:= Nil
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Inicia Envio de Mensagem de Aviso³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	PutMv("MV_WFHTML","T")
	
	oProcess:=TWFProcess():New("PEDCOM","WORKFLOW PARA APROVACAO DE SC")
	oProcess:NewTask('Inicio',"\workflow\htm\comwf004.htm")
	oHtml   := oProcess:oHtml
	
	oHtml:valbyname("Num"		, cNumSc)
	oHtml:valbyname("Req"    	, cSolicit)
	oHtml:valbyname("Emissao"   , cEmissao)
	oHtml:valbyname("diasE"		, cDiasE)
	oHtml:valbyname("it.Item"   , {})
	oHtml:valbyname("it.Cod"  	, {})
	oHtml:valbyname("it.Desc"   , {})
	
	dbSelectArea("TRB")
	dbGoTop()
	
	While !TRB->(EOF())
		aadd(oHtml:ValByName("it.Item")		, TRB->C1_ITEM)
		aadd(oHtml:ValByName("it.Cod")		, TRB->C1_PRODUTO)
		aadd(oHtml:ValByName("it.Desc")		, TRB->C1_DESCRI)
		TRB->(dbSkip())
	End
	
EndIf
TRB->(dbCloseArea())

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Funcoes para Envio do Workflow³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

//envia o e-mail  
Msginfo("E-mail de aprovação da SC enviado para: "+cMailSup)
cUser 			  := Subs(cUsuario,7,15)
oProcess:ClientName(cUser)
oProcess:cTo	  := cMailSup+";"+cMailSol

oProcess:cSubject := "Exclusão por TimeOut - SC N°: "+cNumSc+" - De: "+cSolicit
oProcess:cBody    := ""
oProcess:bReturn  := ""
oProcess:Start()
//RastreiaWF( ID do Processo, Codigo do Processo, Codigo do Status, Descricao Especifica, Usuario )
RastreiaWF(oProcess:fProcessID+'.'+oProcess:fTaskID,"PEDCOM",'100400',"TIMEOUT EXCLUSAO DE WORKFLOW PARA APROVACAO DE SC",cUsername)
oProcess:Free()
oProcess:Finish()
oProcess:= Nil

PutMv("MV_WFHTML",cMvAtt)

//WFSendMail({cEmpant,cFilant})


Return


*------------------------------------------------------------------------------------------------------------------------------------*
* Fonte      * COMWF002 * Autor  * CONSULTORIA ON LINE   * Benedic, Domine Deus, in hac societate quae facit.	Data *  16/04/2014	 *
*------------------------------------------------------------------------------------------------------------------------------------*
* Descricão  * Envia Workflow de Aprovacao de Solicitacao de Compras, quando a aprovacao e feita por ITEM							 *
*------------------------------------------------------------------------------------------------------------------------------------*
* Uso        * 	Renovagro	- Modulo Compras 																						 *
*------------------------------------------------------------------------------------------------------------------------------------*
* Consultor  * Juliano Rezende Ribeiro 																								 *
*------------------------------------------------------------------------------------------------------------------------------------*

User Function COMWF002()

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Declaração de Variaveis³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
Local cMvAtt := GetMv("MV_WFHTML")
Local cAprov := PswRet()[1][11]
Local cMailSup :="" 
LOCAL aMeses	:= {"Jan","Fev","Mar","Abr","Mai","Jun","Jul","Ago","Set","Out","Nov","Dez"}
Local j,m
Private oHtml                      

cAprovIni:=cAprov 
while cAprov $ cAprovIni
      cMailSup +=rtrim(UsrRetMail(cAprov))
      cAprov:=PswRet()[1][11]             
      if cAprov $ cAprovIni
      	cMailSup +=";" 
      endif	   
enddo            


cQuery := " SELECT C1_FILIAL, C1_NUM, C1_EMISSAO, C1_SOLICIT, C1_ITEM, C1_PRODUTO, C1_DESCRI, C1_UM, C1_QUANT, C1_DATPRF, C1_OBS, C1_CC, C1_CODAPRO, C1_QUJE, C1_LOCAL, CTT_DESC01,"
cQuery += " B2_QATU, B1_EMIN, B1_QE, B1_UPRC"
cQuery += " FROM "+RetSqlName('SC1')+" SC1 "

cQuery += " INNER JOIN "+RetSqlName('CTT')+" CTT ON C1_CC = CTT_CUSTO"

cQuery += " INNER JOIN "+RetSqlname('SB2')+" B2 ON C1_PRODUTO = B2_COD AND C1_LOCAL = B2_LOCAL"
cQuery += " INNER JOIN "+RetSqlName('SB1')+" B1 ON C1_PRODUTO = B1_COD"
cQuery += " WHERE C1_NUM = '"+SC1->C1_NUM+"' AND C1_FILIAL = '" + XFILIAL("SC1") + "' AND SC1.D_E_L_E_T_ = ' ' "
cQuery += " AND C1_ITEM = '"+SC1->C1_ITEM+"'"

dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQuery),"TRB", .F., .T.)     

TcSetField("TRB","C1_EMISSAO","D")
TcSetField("TRB","C1_DATPRF","D")

If !TRB->(EOF())
	
	dbSelectArea("TRB")
	TRB->(dbGoTop())
	
	cNumSc		:= TRB->C1_NUM
	cSolicit	:= Subs(cUsuario,7,15)
	cItem		:= TRB->C1_ITEM
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Muda o parametro para enviar no corpo do e-mail³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	PutMv("MV_WFHTML","T")
	
	oProcess:=TWFProcess():New("PEDCOM","WORKFLOW PARA APROVACAO DE SC")
	oProcess:NewTask('Inicio',"\workflow\htm\comwf002.htm")
	oHtml   := oProcess:oHtml
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Dados do Cabecalho³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
  	oHtml:ValByName("diasA"			, cDiasA)
  	oHtml:ValByName("diasE"			, cDiasE)
	oHtml:ValByName("Num"		, TRB->C1_NUM				) //Numero da Cotacao
	oHtml:ValByName("Item1"		, TRB->C1_ITEM 				) //Item Cotacao
	oHtml:ValByName("CC"		, TRB->C1_CC				) //Centro de Custo
	oHtml:ValByName("DescCC"	, TRB->CTT_DESC01			) //Descricao Centro de Custo
	oHtml:ValByName("Req"	  	, Subs(cUsuario,7,15)		) //Nome Requisitante
	oHtml:ValByName("Emissao"	, DTOC(TRB->C1_EMISSAO)		) //Data de Emissao Solicitacao
	//oHtml:ValByName("cAPROV"	, ""						) //Variavel que Retorna "Aprovado / Rejeitado"
	//oHtml:ValByName("cMOTIVO"	, ""						) //Variavel que Retorna o Motivo da Rejeicao
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Saldos em Estoque³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	oHtml:ValByName("Item"		, TRB->C1_ITEM		   		) //Item Cotacao
	oHtml:ValByName("CodProd"	, TRB->C1_PRODUTO	   		) //Cod Produto
	oHtml:ValByName("Desc"		, TRB->C1_DESCRI			) //Descricao Produto
	oHtml:ValByName("SaldoAtu"	, TRANSFORM(TRB->B2_QATU  		, PesqPict("SB2","B2_QATU" ,12))	) //Saldo Atual Estoque
	oHtml:ValByName("EstMin"	, TRANSFORM(TRB->B1_EMIN		, PesqPict("SB1","B1_EMIN" ,12))	) //Ponto de Pedido
	oHtml:ValByName("QuantSol"	, TRANSFORM(TRB->C1_QUANT - TRB->C1_QUJE , PesqPict("SC1","C1_QUANT",12))) //Saldo da Solicitacao
	oHtml:ValByName("UM"		, TRANSFORM(TRB->C1_UM			, PesqPict("SC1","C1_UM"))			) //Unidade de Medida
	oHtml:ValByName("Local"		, TRANSFORM(TRB->C1_LOCAL		, PesqPict("SC1","C1_LOCAL"))		) //Armazem da Solicitacao
	oHtml:ValByName("QuantEmb"	, TRANSFORM(TRB->B1_QE			, PesqPict("SB1","B1_QE"   ,09))	) //Quantidade Por Embalagem
	oHtml:ValByName("UPRC"		, TRANSFORM(TRB->B1_UPRC		, PesqPict("SB1","B1_UPRC",12))		) //Ultimo Preco de Compra
	oHtml:ValByName("Lead" 		, TRANSFORM(CalcPrazo(TRB->C1_PRODUTO,TRB->C1_QUANT), "999")		) //Lead Time
	oHtml:ValByName("DataNec"	, If(Empty(TRB->C1_DATPRF),TRB->C1_EMISSAO,TRB->C1_DATPRF)			)//Data da Necessidade
	oHtml:ValByName("DataCom"	, SomaPrazo(If(Empty(TRB->C1_DATPRF),TRB->C1_EMISSAO,TRB->C1_DATPRF), -CalcPrazo(TRB->C1_PRODUTO,TRB->C1_QUANT)))// Data para Comprar
	oHtml:ValByName("Obs"		, TRANSFORM(TRB->C1_OBS , "@!")										) //Observacao da Cotacao
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Ordens de Produção³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	oHtml:ValByName("op1.OP"		, {})//Coloca em Branco para
	oHtml:ValByName("op1.Prod"		, {})//caso nao tenha nenhuma OP
	oHtml:ValByName("op1.Ini"		, {})
	oHtml:ValByName("op1.QtdOp"		, {})
	oHtml:ValByName("op2.OP"		, {})
	oHtml:ValByName("op2.Prod"		, {})
	oHtml:ValByName("op2.Ini"		, {})
	oHtml:ValByName("op2.QtdOp"		, {})
	oHtml:ValByName("op3.OP"		, {})
	oHtml:ValByName("op3.Prod"		, {})
	oHtml:ValByName("op3.Ini"		, {})
	oHtml:ValByName("op3.QtdOp"		, {})
	
	//Query busca as OPs do produto
	
	cQuery1 := " SELECT D4_OP, D4_DATA, D4_QUANT, C2_PRODUTO"
	cQuery1 += " FROM "+RetSqlName('SD4')+" D4" 	
	cQuery1 += " INNER JOIN "+RetSqlName('SC2')+" C2"       
	If "MSSQL" $ Upper(TcGetDb())
		cQuery1 += " ON SUBSTRING(D4_OP,1,6) = C2_NUM"
		cQuery1 += " AND SUBSTRING(D4_OP,7,2) = C2_ITEM"
		cQuery1 += " AND SUBSTRING(D4_OP,9,3) = C2_SEQUEN"
	Else
		cQuery1 += " ON SUBSTR(D4_OP,1,6) = C2_NUM"
		cQuery1 += " AND SUBSTR(D4_OP,7,2) = C2_ITEM"
		cQuery1 += " AND SUBSTR(D4_OP,9,3) = C2_SEQUEN"	
	Endif		cQuery1 += " WHERE D4_COD = '"+TRB->C1_PRODUTO+"'"
	cQuery1 += " AND D4_QUANT > 0"
	cQuery1 += " AND D4.D_E_L_E_T_ <> '*'"
	cQuery1 += " AND C2.D_E_L_E_T_ <> '*'"
	cQuery1 += " ORDER BY D4_DATA"
	
	dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQuery1),"TRB1", .F., .T.)

	
	TcSetField("TRB1","D4_DATA","D")

dbSelectArea("TRB1")
TRB1->(dbGoTop())
	
If !TRB1->(EOF())
		
		While !TRB1->(EOF())
			aadd(oHtml:ValByName("op1.OP")		, TRB1->D4_OP			) //Numero da OP 1
			aadd(oHtml:ValByName("op1.Prod")	, TRB1->C2_PRODUTO		) //Produto a Ser Produzido OP 1
			aadd(oHtml:ValByName("op1.Ini")		, DTOC(TRB1->D4_DATA)	) //Data da OP 1
			aadd(oHtml:ValByName("op1.QtdOp")	, TRANSFORM(TRB1->D4_QUANT , PesqPict("SD4","D4_QUANT",12))	) //Quantidade OP 1
			TRB1->(dbSkip())
			aadd(oHtml:ValByName("op2.OP")		, TRB1->D4_OP			) //Numero da OP 2
			aadd(oHtml:ValByName("op2.Prod")	, TRB1->C2_PRODUTO		) //Produto a Ser Produzido OP 2
			aadd(oHtml:ValByName("op2.Ini")		, DTOC(TRB1->D4_DATA)	) //Data da OP 2
			aadd(oHtml:ValByName("op2.QtdOp")	, TRANSFORM(TRB1->D4_QUANT , PesqPict("SD4","D4_QUANT",12))	) //Quantidade OP 2
			TRB1->(dbSkip())
			aadd(oHtml:ValByName("op3.OP")		, TRB1->D4_OP			) //Numero da OP 3
			aadd(oHtml:ValByName("op3.Prod")	, TRB1->C2_PRODUTO		) //Produto a Ser Produzido OP 3
			aadd(oHtml:ValByName("op3.Ini")		, DTOC(TRB1->D4_DATA)	) //Data da OP 3
			aadd(oHtml:ValByName("op3.QtdOp")	, TRANSFORM(TRB1->D4_QUANT , PesqPict("SD4","D4_QUANT",12))	) //Quantidade OP 3
			TRB1->(dbSkip())
		End
		
	Else
		
		aadd(oHtml:ValByName("op1.OP")		, "")
		aadd(oHtml:ValByName("op1.Prod")	, "")
		aadd(oHtml:ValByName("op1.Ini")		, "")
		aadd(oHtml:ValByName("op1.QtdOp")	, "")
		aadd(oHtml:ValByName("op2.OP")		, "")
		aadd(oHtml:ValByName("op2.Prod")	, "")
		aadd(oHtml:ValByName("op2.Ini")		, "")
		aadd(oHtml:ValByName("op2.QtdOp")	, "")
		aadd(oHtml:ValByName("op3.OP")		, "")
		aadd(oHtml:ValByName("op3.Prod")	, "")
		aadd(oHtml:ValByName("op3.Ini")		, "")
		aadd(oHtml:ValByName("op3.QtdOp")	, "")
	EndIf
	TRB1->(dbCloseArea())
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Consumo Ultimos 12 Meses³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	//Query busca Consumo do produto
	cQuery2 := " SELECT *"
	cQuery2 += " FROM "+RetSqlName('SB3')+" SB3"
	cQuery2 += " WHERE B3_COD = '"+TRB->C1_PRODUTO+"'"
	cQuery2 += " AND D_E_L_E_T_ <> '*'"
	
	dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQuery2),"TRB2", .F., .T.)
	
If !TRB2->(EOF())
		
		dbSelectArea("TRB2")
		TRB2->(dbGoTop())
		
		cMeses := Space(5)
		nAno := YEAR(dDataBase)
		nMes := MONTH(dDataBase)
		aOrdem := {}
		
		For j := nMes To 1 Step -1 //Preenche Meses Anteriores do Ano Atual
			cMeses += aMeses[j]+"/"+Substr(Str(nAno,4),3,2)
			AADD(aOrdem,j)
		Next j
		
		nAno-- //Volta para Ano Anterior
		
		For j := 12 To nMes+1 Step -1 //Preenche Meses Finais do Ano Anterior
			cMeses += aMeses[j]+"/"+Substr(Str(nAno,4),3,2)
			AADD(aOrdem,j)
		Next j
		
		For j :=1 to 12 //Preenche as variaveis do HTML
			cVarMes := "Mes"+AllTrim(Str(j))
			oHtml:ValByName(cVarMes		, SubStr(cMeses,(j*6),6)) // Meses de Consumo
		Next j
		
		For j := 1 To Len(aOrdem)
			cMes    := StrZero(aOrdem[j],2)
			cCampos := "TRB2->B3_Q"+cMes
			oHtml:ValByName("CMes"+AllTrim(Str(j))	, TRANSFORM(&cCampos , PesqPict("SB3","B3_Q01",9))) //Valor de Consumo nos Meses
		Next j
		
		oHtml:ValByName("MedC"		, TRANSFORM(TRB2->B3_MEDIA, PesqPict("SB3","B3_MEDIA",8))) //Media de Consumo
		
	Else //Caso nao tenha dados
		
		oHtml:ValByName("MedC"		, "")
		For m := 1 To 12
			oHtml:ValByName("CMes"+AllTrim(Str(m))	, "")
			oHtml:ValByName("Mes"+AllTrim(Str(m))	, "")
		Next m
	EndIf
	TRB2->(dbCloseArea())
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Ultimos Pedidos de Compra ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	oHtml:ValByName("it.NumP"			, {})
	oHtml:ValByName("it.ItemP"			, {})
	oHtml:ValByName("it.CodP"			, {})
	oHtml:ValByName("it.LjP"			, {})
	oHtml:ValByName("it.NomeP"			, {})
	oHtml:ValByName("it.QtdeP"			, {})
	oHtml:ValByName("it.UMP"			, {})
	oHtml:ValByName("it.VlrUnP"			, {})
	oHtml:ValByName("it.VlrTotP"		, {})
	oHtml:ValByName("it.EmiP"			, {})
	oHtml:ValByName("it.NecP"			, {})
	oHtml:ValByName("it.PraP"			, {})
	oHtml:ValByName("it.CondP"			, {})
	oHtml:ValByName("it.QtdeEntP"		, {})
	oHtml:ValByName("it.SalP"			, {})
	oHtml:ValByName("it.EliP"			, {})
	
	//Query busca Pedidos do Produto
	cQuery3 := " SELECT C7_NUM, C7_ITEM, C7_FORNECE, C7_LOJA, A2_NOME, C7_QUANT, C7_UM, C7_PRECO, C7_TOTAL, C7_EMISSAO, C7_DATPRF, C7_COND, C7_QUJE, C7_RESIDUO"
	cQuery3 += " FROM "+RetSqlName('SC7')+" C7"
	cQuery3 += " INNER JOIN "+RetSqlName('SA2')+" A2 ON A2_COD = C7_FORNECE AND A2_LOJA = C7_LOJA"
	cQuery3 += " WHERE C7_FILIAL = '"+TRB->C1_FILIAL+"' AND C7_PRODUTO = '"+TRB->C1_PRODUTO+"'"
	cQuery3 += " AND C7.D_E_L_E_T_ <> '*'"
	cQuery3 += " AND A2.D_E_L_E_T_ <> '*'"
	cQuery3 += " ORDER BY C7_EMISSAO DESC"
	

	dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQuery3),"TRB3", .F., .T.)
	
	TcSetField("TRB3","C7_EMISSAO","D")
	TcSetField("TRB3","C7_DATPRF","D")

dbSelectArea("TRB3")
TRB3->(dbGoTop())
	
If !TRB3->(EOF())
		
		nContador := 0
		
		While !TRB3->(EOF())
			
			nContador++
			If nContador > 03 //Numero de Pedidos
				Exit
			EndIf
			
			aadd(oHtml:ValByName("it.NumP")			, TRB3->C7_NUM		)
			aadd(oHtml:ValByName("it.ItemP")		, TRB3->C7_ITEM		)
			aadd(oHtml:ValByName("it.CodP")			, TRB3->C7_FORNECE	)
			aadd(oHtml:ValByName("it.LjP")			, TRB3->C7_LOJA		)
			aadd(oHtml:ValByName("it.NomeP")		, TRB3->A2_NOME		)
			aadd(oHtml:ValByName("it.QtdeP")		, TRANSFORM(TRB3->C7_QUANT , PesqPict("SC7","C7_QUANT",14))	)
			aadd(oHtml:ValByName("it.UMP")			, TRB3->C7_UM		)
			aadd(oHtml:ValByName("it.VlrUnP")		, TRANSFORM(TRB3->C7_PRECO, PesqPict("SC7","c7_preco",14))	)
			aadd(oHtml:ValByName("it.VlrTotP")		, TRANSFORM(TRB3->C7_TOTAL, PesqPict("SC7","c7_total",14))	)
			aadd(oHtml:ValByName("it.EmiP")			, DTOC(TRB3->C7_EMISSAO))
			aadd(oHtml:ValByName("it.NecP")			, DTOC(TRB3->C7_DATPRF)	)
			aadd(oHtml:ValByName("it.PraP")			, TRANSFORM(Val(DTOC(TRB3->C7_DATPRF))-Val(DTOC(TRB3->C7_EMISSAO)), "999"))
			aadd(oHtml:ValByName("it.CondP")		, TRB3->C7_COND		)
			aadd(oHtml:ValByName("it.QtdeEntP")		, TRANSFORM(TRB3->C7_QUJE, PesqPict("SC7","C7_QUJE",14))		)
			aadd(oHtml:ValByName("it.SalP")			, TRANSFORM(If(Empty(TRB3->C7_RESIDUO),TRB3->C7_QUANT-TRB3->C7_QUJE,0), PesqPict("SC7","C7_QUJE",14)))
			aadd(oHtml:ValByName("it.EliP")			, If(Empty(TRB3->C7_RESIDUO),'Não','Sim'))
			
			TRB3->(dbSkip())
		End
		
	Else //Caso nao tenha dados
		
		aadd(oHtml:ValByName("it.NumP")			, "")
		aadd(oHtml:ValByName("it.ItemP")		, "")
		aadd(oHtml:ValByName("it.CodP")			, "")
		aadd(oHtml:ValByName("it.LjP")			, "")
		aadd(oHtml:ValByName("it.NomeP")		, "")
		aadd(oHtml:ValByName("it.QtdeP")		, "")
		aadd(oHtml:ValByName("it.UMP")			, "")
		aadd(oHtml:ValByName("it.VlrUnP")		, "")
		aadd(oHtml:ValByName("it.VlrTotP")		, "")
		aadd(oHtml:ValByName("it.EmiP")			, "")
		aadd(oHtml:ValByName("it.NecP")			, "")
		aadd(oHtml:ValByName("it.PraP")			, "")
		aadd(oHtml:ValByName("it.CondP")		, "")
		aadd(oHtml:ValByName("it.QtdeEntP")		, "")
		aadd(oHtml:ValByName("it.SalP")			, "")
		aadd(oHtml:ValByName("it.EliP")			, "")
		
	EndIf
	TRB3->(dbCloseArea())
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Ultimos Fornecedores³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	
	oHtml:ValByName("it1.CodF"			, {})
	oHtml:ValByName("it1.LjF"			, {})
	oHtml:ValByName("it1.NomeF"			, {})
	oHtml:ValByName("it1.TelF"			, {})
	oHtml:ValByName("it1.ContF"			, {})
	oHtml:ValByName("it1.FaxF"			, {})
	oHtml:ValByName("it1.UlComF"		, {})
	oHtml:ValByName("it1.MunicF"		, {})
	oHtml:ValByName("it1.UFF"			, {})
	oHtml:ValByName("it1.RisF"			, {})
	oHtml:ValByName("it1.CodForF"		, {})
	
	If mv_par03 == 1 // Amarracao por Produto
		
		//Query busca Fornecedores do Produto
		cQuery4 := " SELECT A5_FORNECE, A5_LOJA, A2_NOME, A2_TEL, A2_CONTATO, A2_FAX, A2_ULTCOM, A2_MUN, A2_EST, A2_RISCO, A5_CODPRF"
		cQuery4 += " FROM "+RetSqlName('SA5')+" A5"
		cQuery4 += " INNER JOIN "+RetSqlName('SA2')+" A2 ON A5_FORNECE = A2_COD AND A5_LOJA = A2_LOJA"
		cQuery4 += " WHERE A5_PRODUTO = '"+TRB->C1_PRODUTO+"'"
		cQuery4 += " AND A5.D_E_L_E_T_ <> '*'"
		cQuery4 += " AND A2.D_E_L_E_T_ <> '*'"
		cQuery4 += " order by  A2_ULTCOM DESC"
		
		dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQuery4),"TRB4", .F., .T.)
		
		TcSetField("TRB4","A2_ULTCOM","D")

		dbSelectArea("TRB4")
		TRB4->(dbGoTop())		

		If !TRB4->(EOF())
			
			nContador := 0
			
			While !TRB4->(EOF())
				
				nContador++
				If nContador > 03 //Numero de Fornecedores
					Exit
				EndIf
				
				aadd(oHtml:ValByName("it1.CodF")		, TRB4->A5_FORNECE	) //Codigo do Fornecedor
				aadd(oHtml:ValByName("it1.LjF")			, TRB4->A5_LOJA		) //Codigo da Loja
				aadd(oHtml:ValByName("it1.NomeF")		, TRB4->A2_NOME		) //Nome do Fornecedor
				aadd(oHtml:ValByName("it1.TelF")		, TRB4->A2_TEL		) //Telefone do Fornecedor
				aadd(oHtml:ValByName("it1.ContF")		, TRB4->A2_CONTATO	) //Contato no Fornecedor
				aadd(oHtml:ValByName("it1.FaxF")		, TRB4->A2_FAX		) //Fax no Fornecedor
				aadd(oHtml:ValByName("it1.UlComF")		, DTOC(TRB4->A2_ULTCOM)	) //Ultima Compra com o Fornecedor
				aadd(oHtml:ValByName("it1.MunicF")		, TRB4->A2_MUN		) //Municipio do Fornecedor
				aadd(oHtml:ValByName("it1.UFF")			, TRB4->A2_EST		) //Estado do Fornecedor
				aadd(oHtml:ValByName("it1.RisF")		, TRB4->A2_RISCO	) //Risco do Fornecedor
				aadd(oHtml:ValByName("it1.CodForF")		, TRB4->A5_CODPRF	) //Codigo no Forncedor
				
				TRB4->(dbSkip())
			End
			
		Else //Caso nao tenha dados
			
			aadd(oHtml:ValByName("it1.CodF")		, ""	) //Codigo do Fornecedor
			aadd(oHtml:ValByName("it1.LjF")			, ""	) //Codigo da Loja
			aadd(oHtml:ValByName("it1.NomeF")		, ""	) //Nome do Fornecedor
			aadd(oHtml:ValByName("it1.TelF")		, ""	) //Telefone do Fornecedor
			aadd(oHtml:ValByName("it1.ContF")		, ""	) //Contato no Fornecedor
			aadd(oHtml:ValByName("it1.FaxF")		, ""	) //Fax no Fornecedor
			aadd(oHtml:ValByName("it1.UlComF")		, ""	) //Ultima Compra com o Fornecedor
			aadd(oHtml:ValByName("it1.MunicF")		, ""	) //Municipio do Fornecedor
			aadd(oHtml:ValByName("it1.UFF")			, ""	) //Estado do Fornecedor
			aadd(oHtml:ValByName("it1.RisF")		, ""	) //Risco do Fornecedor
			aadd(oHtml:ValByName("it1.CodForF")		, ""	) //Codigo no Forncedor
			
		EndIf
		TRB4->(dbCloseArea())
		
	Else
		
		//Query busca Fornecedores do Grupo de Produtos
		cQuery4 := " SELECT AD_FORNECE, AD_LOJA, A2_NOME, A2_TEL, A2_CONTATO, A2_FAX, A2_ULTCOM, A2_MUN, A2_EST, A2_RISCO"
		cQuery4 += " FROM "+RetSqlName('SB1')+" B1"
		cQuery4 += " INNER JOIN "+RetSqlName('SAD')+" AD ON B1_GRUPO = AD_GRUPO"
		cQuery4 += " INNER JOIN "+RetSqlName('SA2')+" A2 ON AD_FORNECE = A2_COD AND AD_LOJA = A2_LOJA"
		cQuery4 += " WHERE B1_COD = '"+TRB->C1_PRODUTO+"'"
		cQuery4 += " AND AD.D_E_L_E_T_ <> '*'"
		cQuery4 += " AND A2.D_E_L_E_T_ <> '*'"
		cQuery4 += " AND B1.D_E_L_E_T_ <> '*'"
		cQuery4 += " ORDER BY  A2_ULTCOM DESC"
		
		
		dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQuery4),"TRB4", .F., .T.)
		
		TcSetField("TRB4","A2_ULTCOM","D")
		
		If !TRB4->(EOF())
			
			dbSelectArea("TRB4")
			TRB4->(dbGoTop())
			
			nContador := 0
			
			While !TRB4->(EOF())
				
				nContador++
				If nContador > 03 //Numero de Fornecedores
					Exit
				EndIf
				
				aadd(oHtml:ValByName("it1.CodF")		, TRB4->AD_FORNECE	) //Codigo do Fornecedor
				aadd(oHtml:ValByName("it1.LjF")			, TRB4->AD_LOJA		) //Codigo da Loja
				aadd(oHtml:ValByName("it1.NomeF")		, TRB4->A2_NOME		) //Nome do Fornecedor
				aadd(oHtml:ValByName("it1.TelF")		, TRB4->A2_TEL		) //Telefone do Fornecedor
				aadd(oHtml:ValByName("it1.ContF")		, TRB4->A2_CONTATO	) //Contato no Fornecedor
				aadd(oHtml:ValByName("it1.FaxF")		, TRB4->A2_FAX		) //Fax no Fornecedor
				aadd(oHtml:ValByName("it1.UlComF")		, DTOC(TRB4->A2_ULTCOM)	) //Ultima Compra com o Fornecedor
				aadd(oHtml:ValByName("it1.MunicF")		, TRB4->A2_MUN		) //Municipio do Fornecedor
				aadd(oHtml:ValByName("it1.UFF")			, TRB4->A2_EST		) //Estado do Fornecedor
				aadd(oHtml:ValByName("it1.RisF")		, TRB4->A2_RISCO	) //Risco do Fornecedor
				aadd(oHtml:ValByName("it1.CodForF")		, ""				) //Codigo no Forncedor
				TRB4->(dbSkip())
			End
			
		Else //Caso nao tenha dados
			
			aadd(oHtml:ValByName("it1.CodF")		, ""	) //Codigo do Fornecedor
			aadd(oHtml:ValByName("it1.LjF")			, ""	) //Codigo da Loja
			aadd(oHtml:ValByName("it1.NomeF")		, ""	) //Nome do Fornecedor
			aadd(oHtml:ValByName("it1.TelF")		, ""	) //Telefone do Fornecedor
			aadd(oHtml:ValByName("it1.ContF")		, ""	) //Contato no Fornecedor
			aadd(oHtml:ValByName("it1.FaxF")		, ""	) //Fax no Fornecedor
			aadd(oHtml:ValByName("it1.UlComF")		, ""	) //Ultima Compra com o Fornecedor
			aadd(oHtml:ValByName("it1.MunicF")		, ""	) //Municipio do Fornecedor
			aadd(oHtml:ValByName("it1.UFF")			, ""	) //Estado do Fornecedor
			aadd(oHtml:ValByName("it1.RisF")		, ""	) //Risco do Fornecedor
			aadd(oHtml:ValByName("it1.CodForF")		, ""	) //Codigo no Forncedor
			
		EndIf
		TRB4->(dbCloseArea())
		
	EndIf
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Funcoes para Envio do Workflow³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	//envia o e-mail
	Msginfo("E-mail de aprovação da SC enviado para: "+cMailSup)
	cUser 			  := Subs(cUsuario,7,15)
	oProcess:ClientName(cUser)
	oProcess:cTo	  := cMailSup

	oProcess:cSubject := "Aprovação de SC N°: "+cNumSc+" Item: "+cItem+" - De: "+cSolicit
	oProcess:cBody    := ""
//	oProcess:bReturn  := "U_COMWF02a()"
	//oProcess:bTimeOut := {{"U_COMWF02b()", Val(cDiasA) , 0, 0 },{"U_COMWF02c()", Val(cDiasE) , 0, 0 }}
	//oProcess:bTimeOut := {{"U_COMWF02b()",0, 0, 05 },{"U_COMWF02c()",0, 0, 10 }}
	oProcess:Start()
	//RastreiaWF( ID do Processo, Codigo do Processo, Codigo do Status, Descricao Especifica, Usuario )
	RastreiaWF(oProcess:fProcessID+'.'+oProcess:fTaskID,"PEDCOM","100100","ENVIO DE WORKFLOW PARA APROVACAO DE SC",cUsername)
	oProcess:Free()
	oProcess:= Nil
	
	PutMv("MV_WFHTML",cMvAtt)
	
Else
	MsgStop("Foi encontrado um problema na Geração do E-Mail de Aprovação. Favor avisar o Depto de Informática. NREC =","ATENÇÃO!")
EndIf

TRB->(dbCloseArea())

Return


*------------------------------------------------------------------------------------------------------------------------------------*
* Fonte      * COMWF02a * Autor  * CONSULTORIA ON LINE   * Benedic, Domine Deus, in hac societate quae facit.	Data *  16/04/2014	 *
*------------------------------------------------------------------------------------------------------------------------------------*
* Descricão  * Retor Workflow de Aprovacao de Solicitacao de Compras																 *
*------------------------------------------------------------------------------------------------------------------------------------*
* Uso        * 	Renovagro	- Modulo Compras 																						 *
*------------------------------------------------------------------------------------------------------------------------------------*
* Consultor  * Juliano Rezende Ribeiro 																								 *
*------------------------------------------------------------------------------------------------------------------------------------*


User Function COMWF02a(oProcess)

Local cMvAtt := GetMv("MV_WFHTML")
Local cNumSc	:= oProcess:oHtml:RetByName("Num")
Local cItemSc	:= oProcess:oHtml:RetByName("Item")
Local cSolicit	:= oProcess:oHtml:RetByName("Req")
Local cEmissao	:= oProcess:oHtml:RetByName("Emissao")
//Local cDiasA	:= oProcess:oHtml:RetByName("diasA")
//Local cDiasE	:= oProcess:oHtml:RetByName("diasE")
Local cCod		:= oProcess:oHtml:RetByName("CodProd")
Local cDesc		:= oProcess:oHtml:RetByName("Desc")
Local cAprov	:= oProcess:oHtml:RetByName("cAPROV")
Local cMotivo	:= oProcess:oHtml:RetByName("cMOTIVO")

Private oHtml

ConOut("Atualizando SC:"+cNumSc+" Item:"+cItemSc)
MSGINFO("TESTE")

cFilAnt:=	cFilial
cEmpAnt:=	cEmpresa
DBSELECTAREA("SM0")
DBSEEK(cEmpresa+cFilial)

cQuery := " UPDATE "+RETSQLNAME("SC1")                                
cQuery += " SET C1_APROV = '"+cAprov+"'"
cQuery += " WHERE C1_NUM = '"+cNumSC+"' AND C1_ITEM='"+cItemSc+"' AND C1_FILIAL = '" + XFILIAL("SC1") + "' AND D_E_L_E_T_ = ' ' "


TcSqlExec(cQuery)
TCREFRESH(RetSqlName("SC1"))

//RastreiaWF( ID do Processo, Codigo do Processo, Codigo do Status, Descricao Especifica, Usuario )
RastreiaWF(oProcess:fProcessID+'.'+oProcess:fTaskID,"PEDCOM",'100200',"RETOR DE WORKFLOW PARA APROVACAO DE SC",cUsername)

oProcess:Finish()
oProcess:Free()
oProcess:= Nil

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Inicia Envio de Mensagem de Aviso³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
PutMv("MV_WFHTML","T")

oProcess:=TWFProcess():New("PEDCOM","WORKFLOW PARA APROVACAO DE SC")
If cAprov == "L" //Verifica se foi aprovado
	oProcess:NewTask('Inicio',"\workflow\HTM\COMWF005.htm")
ElseIf cAprov == "R" //Verifica se foi rejeitado
	oProcess:NewTask('Inicio',"\workflow\HTM\COMWF006.htm")
EndIf
oHtml   := oProcess:oHtml

oHtml:valbyname("Num"		, cNumSc)
oHtml:valbyname("Req"    	, cSolicit)
oHtml:valbyname("Emissao"   , cEmissao)
oHtml:valbyname("Motivo"   , cMotivo)
oHtml:valbyname("it.Item"   , {})
oHtml:valbyname("it.Cod"  	, {})
oHtml:valbyname("it.Desc"   , {})
aadd(oHtml:ValByName("it.Item")		, cItemSc)
aadd(oHtml:ValByName("it.Cod")		, cCod)
aadd(oHtml:ValByName("it.Desc")		, cDesc)

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Funcoes para Envio do Workflow³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
//envia o e-mail
Msginfo("E-mail de aprovação da SC enviado para: "+cMailSup)
cUser 			  := Subs(cUsuario,7,15)
oProcess:ClientName(cUser)
oProcess:cTo	  := cMailSup

If cAprov == "L" //Verifica se foi aprovado
	oProcess:cSubject := "SC N°: "+cNumSc+" - Item: "+cItemSc+" - Aprovada"
ElseIf cAprov == "R" //Verifica se foi rejeitado
	oProcess:cSubject := "SC N°: "+cNumSc+" - Item: "+cItemSc+" - Reprovada"
EndIf

oProcess:cBody    := ""
oProcess:bReturn  := ""
oProcess:Start()

//RastreiaWF( ID do Processo, Codigo do Processo, Codigo do Status, Descricao Especifica, Usuario )
If cAprov == "L" //Verifica se foi aprovado
	RastreiaWF(oProcess:fProcessID+'.'+oProcess:fTaskID,"PEDCOM",'100500',"TIMEOUT DE WORKFLOW PARA APROVACAO DE SC",cUsername)
ElseIf cAprov == "R" //Verifica se foi rejeitado
	RastreiaWF(oProcess:fProcessID+'.'+oProcess:fTaskID,"PEDCOM",'100600',"TIMEOUT DE WORKFLOW PARA APROVACAO DE SC",cUsername)
EndIf

oProcess:Free()
oProcess:Finish()
oProcess:= Nil

PutMv("MV_WFHTML",cMvAtt)


//WFSendMail({cEmpant,cFilant})


Return

*------------------------------------------------------------------------------------------------------------------------------------*
* Fonte      * COMWF02b * Autor  * CONSULTORIA ON LINE   * Benedic, Domine Deus, in hac societate quae facit.	Data *  16/04/2014	 *
*------------------------------------------------------------------------------------------------------------------------------------*
* Descricão  * Envia um Aviso para Aprovador apos periodo de TIMEOUT																 *
*------------------------------------------------------------------------------------------------------------------------------------*
* Uso        * 	Renovagro	- Modulo Compras 																						 *
*------------------------------------------------------------------------------------------------------------------------------------*
* Consultor  * Juliano Rezende Ribeiro 																								 *
*------------------------------------------------------------------------------------------------------------------------------------*

User Function COMWF02b(oProcess)

Local cMvAtt 	:= GetMv("MV_WFHTML")
Local cNumSc	:= oProcess:oHtml:RetByName("Num")
Local cItemSc	:= oProcess:oHtml:RetByName("Item")
Local cSolicit	:= oProcess:oHtml:RetByName("Req")
Local cEmissao	:= oProcess:oHtml:RetByName("Emissao")
Local cDiasA	:= oProcess:oHtml:RetByName("diasA")
Local cDiasE	:= oProcess:oHtml:RetByName("diasE")
Local cCod		:= oProcess:oHtml:RetByName("CodProd")
Local cDesc		:= oProcess:oHtml:RetByName("Desc")
Private oHtml

ConOut("AVISO POR TIMEOUT SC:"+cNumSc+" Item:"+cItemSc+" Solicitante:"+cSolicit)

oProcess:Free()
oProcess:= Nil

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Inicia Envio de Mensagem de Aviso³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
PutMv("MV_WFHTML","T")

oProcess:=TWFProcess():New("PEDCOM","WORKFLOW PARA APROVACAO DE SC")
oProcess:NewTask('Inicio',"\workflow\HTM\COMWF003.htm")
oHtml   := oProcess:oHtml

oHtml:valbyname("Num"		, cNumSc)
oHtml:valbyname("Req"    	, cSolicit)
oHtml:valbyname("Emissao"   , cEmissao)
oHtml:valbyname("diasA"   	, cDiasA)
oHtml:valbyname("diasE"   	, Val(cDiasE)-Val(cDiasA))
oHtml:valbyname("it.Item"   , {})
oHtml:valbyname("it.Cod"  	, {})
oHtml:valbyname("it.Desc"   , {})
aadd(oHtml:ValByName("it.Item")		, cItemSc)
aadd(oHtml:ValByName("it.Cod")		, cCod)
aadd(oHtml:ValByName("it.Desc")		, cDesc)

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Funcoes para Envio do Workflow³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

//envia o e-mail
Msginfo("E-mail de aprovação da SC enviado para: "+cMailSup)
cUser 			  := Subs(cUsuario,7,15)
oProcess:ClientName(cUser)
oProcess:cTo	  := cMailSup

oProcess:cSubject := "Aviso de TimeOut de SC N°: "+cNumSc+" Item: "+cItemSc+" - De: "+cSolicit
oProcess:cBody    := ""
oProcess:bReturn  := ""
oProcess:Start()
//RastreiaWF( ID do Processo, Codigo do Processo, Codigo do Status, Descricao Especifica, Usuario )
RastreiaWF(oProcess:fProcessID+'.'+oProcess:fTaskID,"PEDCOM",'100300',"TIMEOUT DE WORKFLOW PARA APROVACAO DE SC",cUsername)
oProcess:Free()
oProcess:Finish()
oProcess:= Nil

PutMv("MV_WFHTML",cMvAtt)

//WFSendMail({cEmpant,cFilant})


Return

*------------------------------------------------------------------------------------------------------------------------------------*
* Fonte      * COMWF02c * Autor  * CONSULTORIA ON LINE   * Benedic, Domine Deus, in hac societate quae facit.	Data *  16/04/2014	 *
*------------------------------------------------------------------------------------------------------------------------------------*
* Descricão  * Exclui a solicitacao apos um periodo de TIMEOUT																		 *
*------------------------------------------------------------------------------------------------------------------------------------*
* Uso        * 	Renovagro	- Modulo Compras 																						 *
*------------------------------------------------------------------------------------------------------------------------------------*
* Consultor  * Juliano Rezende Ribeiro 																								 *
*------------------------------------------------------------------------------------------------------------------------------------*

User Function COMWF02c(oProcess)
Local cMvAtt 	:= GetMv("MV_WFHTML")
Local cNumSc	:= oProcess:oHtml:RetByName("Num")
Local cItemSc	:= oProcess:oHtml:RetByName("Item")
Local cSolicit	:= oProcess:oHtml:RetByName("Req")
Local cEmissao	:= oProcess:oHtml:RetByName("Emissao")
Local cDiasE	:= oProcess:oHtml:RetByName("diasE")
Local cCod		:= oProcess:oHtml:RetByName("CodProd")
Local cDesc		:= oProcess:oHtml:RetByName("Desc")
Local cCodSol	:= RetCodUsr(cSolicit)
Local cMailSol 	:= UsrRetMail(cCodSol)
Private oHtml

ConOut("EXCLUSAO POR TIMEOUT SC:"+cNumSc+" Item:"+cItemSc+" Solicitante:"+cSolicit)

cQuery := " UPDATE "+RETSQLNAME("SC1")                                
cQuery += " SET D_E_L_E_T_ = '*'"
cQuery += " WHERE C1_NUM = '"+cNumSC+"'  AND C1_FILIAL = '" + XFILIAL("SC1") + "' AND D_E_L_E_T_ = ' ' "


TcSqlExec(cQuery)
TCREFRESH(RetSqlName("SC1"))

oProcess:Finish()
oProcess:Free()
oProcess:= Nil

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Inicia Envio de Mensagem de Aviso³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
PutMv("MV_WFHTML","T")

oProcess:=TWFProcess():New("PEDCOM","WORKFLOW PARA APROVACAO DE SC")
oProcess:NewTask('Inicio',"\workflow\HTM\COMWF004.htm")
oHtml   := oProcess:oHtml

oHtml:valbyname("Num"		, cNumSc)
oHtml:valbyname("Req"    	, cSolicit)
oHtml:valbyname("Emissao"   , cEmissao)
oHtml:valbyname("diasE"		, cDiasE)
oHtml:valbyname("it.Item"   , {})
oHtml:valbyname("it.Cod"  	, {})
oHtml:valbyname("it.Desc"   , {})
aadd(oHtml:ValByName("it.Item")		, cItemSc)
aadd(oHtml:ValByName("it.Cod")		, cCod)
aadd(oHtml:ValByName("it.Desc")		, cDesc)

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Funcoes para Envio do Workflow³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

//envia o e-mail
Msginfo("E-mail de aprovação da SC enviado para: "+cMailSup)
cUser 			  := Subs(cUsuario,7,15)
oProcess:ClientName(cUser)
oProcess:cTo	  := cMailSup+";"+cMailSol

oProcess:cSubject := "Exclusão por TimeOut - SC N°: "+cNumSc+" Item: "+cItemSc+" - De: "+cSolicit
oProcess:cBody    := ""
oProcess:bReturn  := ""
oProcess:Start()
//RastreiaWF( ID do Processo, Codigo do Processo, Codigo do Status, Descricao Especifica, Usuario )
RastreiaWF(oProcess:fProcessID+'.'+oProcess:fTaskID,"PEDCOM",'100400',"TIMEOUT EXCLUSAO DE WORKFLOW PARA APROVACAO DE SC",cUsername)
oProcess:Free()
oProcess:Finish()
oProcess:= Nil

PutMv("MV_WFHTML",cMvAtt)

//WFSendMail({cEmpant,cFilant})


Return


Static Function _InfoUSR(__CUSERID )
PswOrder(1)
PswSeek( __CUSERID, .T. )  
Return(PswRet()[1][11])    // Retorna vetor com informações do usuário


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
*Constultor  * Juliano Rezende Ribeiro																								 *
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


*------------------------------------------------------------------------------------------------------------------------------------*
* Fonte      * MT110BLO * Autor  * CONSULTORIA ON LINE   * Benedic, Domine Deus, in hac societate quae facit.	Data *  17/04/2015   *
*------------------------------------------------------------------------------------------------------------------------------------*
* Descricão  *  PONTO DE ENTRADA NA APROVACAO DA SOLICITACAO DE COMPRAS															     *
*------------------------------------------------------------------------------------------------------------------------------------*
* Uso        * Compras			                     													                             *
*------------------------------------------------------------------------------------------------------------------------------------*
*Constultor  * Juliano Rezende Ribeiro																								 *
*------------------------------------------------------------------------------------------------------------------------------------*


User Function MT110BLO()

Local lRet1  := .T. 
Local cAprovIni := ""


PswOrder(1)
pswSeek(SC1->C1_USER,.t.)
cAprovIni := PswRet()[1][11] 
pswSeek(__CUSERID,.t.)

if __CUSERID $ cAprovIni
	lRet1 := .T.
else
	MsgAlert("Usuário não autorizado a aprovar esta solicitação.","Atenção!")
	lRet1 := .F.
EndIf

Return(lRet1)

#include "protheus.ch" 

*------------------------------------------------------------------------------------------------------------------------------------*
* Fonte      * MT110COR * Autor  * CONSULTORIA ON LINE   * Benedic, Domine Deus, in hac societate quae facit.	Data *  17/04/2015   *
*------------------------------------------------------------------------------------------------------------------------------------*
* Descricão  *  PONTO DE ENTRADA NA APROVACAO DA SOLICITACAO DE COMPRAS																 *
*------------------------------------------------------------------------------------------------------------------------------------*
* Uso        * Compras			                     													                             *
*------------------------------------------------------------------------------------------------------------------------------------*
*Constultor  * Juliano Rezende Ribeiro																								 *
*------------------------------------------------------------------------------------------------------------------------------------*
           
User Function MT110COR()   

Local aAllUser	:= {}
Local aAllGroup	:= {}      
Local lret:=.T. 
Local _j    

Processa({||A085AllUser(@aAllUser,@aAllGroup)},,"Verificando Usuarios...") //STR0023  //"Verificando Usuarios..."                  

DBSELECTAREA("SAI")  
dbgotop()
dbSetOrder(2)
dbSeek(xFilial("SAI")+__CUSERID) 
if __CUSERID==SAI->AI_USER
	lRet := .T.
else
	lRet := .F.
	DBSELECTAREA("SAI")
	dbgotop()
	dbSetOrder(1)
	For _j:=1 to len(aAllGroup)
		GROUPSOL:=aAllGroup[_j,1,1]
		dbSeek(xFilial("SAI")+GROUPSOL)
		if found()
			lRet := .T.
		Else
			MsgAlert("Usuário/Grupo não esta cadastrado como solicitante!","Atenção!")
			lRet := .F.
			aRotina:={}
		EndIf
	Next
	if lRet:=.F.
		MsgAlert("Usuário/Grupo não esta cadastrado como solicitante!","Atenção!")
		aRotina:={}
	endif
Endif

Return(NIL)            


Static Function A085AllUser(aAllUser,aAllGroup) 
//Local cEmpsis:=cEmpAnt,cFilsis:=cFilAnt

ProcRegua(4)
IncProc()
IncProc()
aAllUser := AllUsers()
IncProc()
IncProc()
aAllGroup := AllGroups()

Return

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³MT110FIL  ºAutor  ³ON LINE      - JULIANO º Data ³  22/06/11   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³PONTO DE ENTRADA NO FILTRO DO MBROWE DE SOLICITACAO DE COMPRº±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ SIGACOM                       	                          º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/


*------------------------------------------------------------------------------------------------------------------------------------*
* Fonte      * MT110FIL * Autor  * CONSULTORIA ON LINE   * Benedic, Domine Deus, in hac societate quae facit.	Data *  16/04/2014	 *
*------------------------------------------------------------------------------------------------------------------------------------*
* Descricão  * Ponto de entrada no filtro da MBROWSE na solicitação de compra.														 *
*------------------------------------------------------------------------------------------------------------------------------------*
* Uso        * 	Renovagro	- Modulo Compras 																						 *
*------------------------------------------------------------------------------------------------------------------------------------*
* Consultor  * Juliano Rezende Ribeiro 																								 *
*------------------------------------------------------------------------------------------------------------------------------------*


User Function MT110FIL()


cRet := ""
CPERG := "COMRD1"
                 
ValidPerg()
SetKey( 121 ,{|| Pergunte("COMRD1",.T.)})

Return (cRet)

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³ValidPerg ºAutor  ³ON LINE      - JULIANO º Data ³  22/06/11   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³Cria pergunta no e o help do SX1                            º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ SIGACOM                                                    º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
*------------------------------------------------------------------------------------------------------------------------------------*
* Fonte      * VALIDPERG * Autor  * CONSULTORIA ON LINE   * Benedic, Domine Deus, in hac societate quae facit.	Data *  16/04/2014	 *
*------------------------------------------------------------------------------------------------------------------------------------*
* Descricão  * Cria pergunta e help no SX1 referente a solicitação de compras.														 *
*------------------------------------------------------------------------------------------------------------------------------------*
* Uso        * 	Renovagro	- Modulo Compras 																						 *
*------------------------------------------------------------------------------------------------------------------------------------*
* Consultor  * Juliano Rezende Ribeiro 																								 *
*------------------------------------------------------------------------------------------------------------------------------------*



Static Function ValidPerg()

Local cKey := ""
Local aHelpEng := {}
Local aHelpPor := {}
Local aHelpSpa := {}

//PutSx1(cGrupo,cOrdem,CPERGunt             ,cPerSpa               ,cPerEng               ,cVar     ,cTipo ,nTamanho,nDecimal,nPresel,cGSC,cValid,cF3, cGrpSxg    ,cPyme,cVar01    ,cDef01     ,cDefSpa1,cDefEng1,cCnt01,cDef02  ,cDefSpa2,cDefEng2,cDef03,cDefSpa3,cDefEng3,cDef04,cDefSpa4,cDefEng4,cDef05,cDefSpa5,cDefEng5,aHelpPor,aHelpEng,aHelpSpa,cHelp)
PutSx1(CPERG,"01"   ,"N° de Pedidos?      ",""                    ,""                    ,"mv_ch1","N"   ,02      ,0       ,0      , "G",""    ,"" ,""         ,""   ,"mv_par01",""    	,""      ,""      ,""    ,""	   	,""     ,""      ,""    	,""      ,""      ,""    ,""      ,""     ,""    ,""      ,""      ,""      ,""      ,""      ,"")
PutSx1(CPERG,"02"   ,"N° de Fornecedores? ",""                    ,""                    ,"mv_ch2","N"   ,02      ,0       ,0      , "G",""    ,"" ,""         ,""   ,"mv_par02",""       ,""      ,""      ,""    ,""		,""     ,""      ,""		,""      ,""      ,""    ,""      ,""     ,""    ,""      ,""     ,""      ,""      ,""      ,"")
PutSx1(CPERG,"03"   ,"Fornec Prod/Grupo?  ",""                    ,""                    ,"mv_ch3","N"   ,01      ,0       ,0      , "C",""    ,"" ,""         ,""   ,"mv_par03","Produto",""      ,""      ,""    ,"Grupo" 	,""     ,""      ,""    	,""      ,""      ,""    ,""      ,""     ,""    ,""      ,""      ,""      ,""      ,""      ,"")
PutSx1(CPERG,"04"   ,"Aprova por Item/Sol?",""                    ,""                    ,"mv_ch4","N"   ,01      ,0       ,0      , "C",""    ,"" ,""         ,""   ,"mv_par04","Item"   	,""      ,""      ,""    ,"Solicita",""     ,""      ,""    	,""      ,""      ,""    ,""      ,""     ,""    ,""      ,""      ,""      ,""      ,""      ,"")

cKey     := "P.COMRD0101."
aHelpEng := {}
aHelpPor := {}
aHelpSpa := {}
aAdd(aHelpEng,"")
aAdd(aHelpEng,"")
aAdd(aHelpPor,"Informe o número de Pedidos que deseja ")
aAdd(aHelpPor,"imprimir.    ")
aAdd(aHelpSpa,"")
aAdd(aHelpSpa,"")
PutSX1Help(cKey,aHelpPor,aHelpEng,aHelpSpa)

cKey     := "P.COMRD0102."
aHelpEng := {}
aHelpPor := {}
aHelpSpa := {}
aAdd(aHelpEng,"")
aAdd(aHelpEng,"")
aAdd(aHelpPor,"Informe o numero de Fornecedores que ")
aAdd(aHelpPor,"deseja imprimir.   ")
aAdd(aHelpSpa,"")
aAdd(aHelpSpa,"")
PutSX1Help(cKey,aHelpPor,aHelpEng,aHelpSpa)

cKey     := "P.COMRD0103."
aHelpEng := {}
aHelpPor := {}
aHelpSpa := {}
aAdd(aHelpEng,"")
aAdd(aHelpEng,"")
aAdd(aHelpPor,"Escolha se o Fornecedor será escolhido")
aAdd(aHelpPor,"por Produto ou Grupo")
aAdd(aHelpSpa,"")
aAdd(aHelpSpa,"")
PutSX1Help(cKey,aHelpPor,aHelpEng,aHelpSpa)

cKey     := "P.COMRD0104."
aHelpEng := {}
aHelpPor := {}
aHelpSpa := {}
aAdd(aHelpEng,"")
aAdd(aHelpEng,"")
aAdd(aHelpPor,"Escolha se a aprovacao da Solilitação")
aAdd(aHelpPor,"será por ITEM ou por SOLICITAÇÃO.")
aAdd(aHelpSpa,"")
aAdd(aHelpSpa,"")
PutSX1Help(cKey,aHelpPor,aHelpEng,aHelpSpa)

Return

*------------------------------------------------------------------------------------------------------------------------------------*
* Fonte      * MT110TOK * Autor  * CONSULTORIA ON LINE   * Benedic, Domine Deus, in hac societate quae facit.	Data *  16/04/2014	 *
*------------------------------------------------------------------------------------------------------------------------------------*
* Descricão  * Ponto de entrada para envio de email para aprovacao da solicitacao de compra											 *
*------------------------------------------------------------------------------------------------------------------------------------*
* Uso        * 	Renovagro	- Modulo Compras 																						 *
*------------------------------------------------------------------------------------------------------------------------------------*
* Consultor  * Juliano Rezende Ribeiro 																								 *
*------------------------------------------------------------------------------------------------------------------------------------*

User Function MT110TOK() 

	Local lret:=.T.
	Local nPosprd:=ascan(aheader, {|x| alltrim(x[2]) == "C1_PRODUTO"})
	Local lHelp:=.T.
	
	lRet:=	MAVLDSOLIC(ACOLS[N,nPosprd],usrRetGrp(),RetcodUsr(),lHelp) 
	
Return(lret)


/*

User Function MT110TOK()
Local aArea := GetArea()
Local lRet	:= .F.


//If !(Alltrim(SC1->C1_CODAPRO) == "")   
 	lRet := .T.

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Envia Workflow para aprovacao da Solicitacao de Compras ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If INCLUI .OR. ALTERA //Verifica se e Inclusao ou Alteracao da Solicitacao
	MsgRun("Enviando Workflow para Aprovador da Solicitação, Aguarde...","",{|| CursorWait(), U_COMRD001() ,CursorArrow()})
EndIf

//Endif	

RestArea(aArea)

Return(lRet) 


*/


#INCLUDE "PROTHEUS.CH"
#INCLUDE "TBICONN.CH"
#INCLUDE "RWMAKE.CH"
#INCLUDE "FILEIO.CH"
#INCLUDE "TOPCONN.CH"   
#INCLUDE "Ap5Mail.ch"

*------------------------------------------------------------------------------------------------------------------------------------*
* Fonte      * M110STTS * Autor  * CONSULTORIA ON LINE   * Benedic, Domine Deus, in hac societate quae facit.	Data *  16/04/2014	 *
*------------------------------------------------------------------------------------------------------------------------------------*
* Descricão  * Ponto de entrada para gravar campo memo.																				 *
*------------------------------------------------------------------------------------------------------------------------------------*
* Uso        * 	Renovagro	- Modulo Compras 																						 *
*------------------------------------------------------------------------------------------------------------------------------------*
* Consultor  * Juliano Rezende Ribeiro 																												  *
*------------------------------------------------------------------------------------------------------------------------------------*

User Function M110STTS()

Local aArea     := GetArea()
          
//MSMM(SC1->C1_CODOBS,,,aCols[n][aScan(aHeader,{|x| UPPER(AllTrim(x[2]))=="C1_OBSMEMO" })],1,,,"SC1","C1_CODOBS")    

If INCLUI .OR. ALTERA //Verifica se e Inclusao ou Alteracao da Solicitacao   
//    MSMM(SC1->C1_CODOBS,,,aCols[n][aScan(aHeader,{|x| UPPER(AllTrim(x[2]))=="C1_OBSMEMO" })],1,,,"SC1","C1_CODOBS")    
	MsgRun("Enviando Workflow para Aprovador da Solicitação, Aguarde...","",{|| CursorWait(), U_COMRD001() ,CursorArrow()})    
//	RecLock("SC1",.F.)
//	SC1->C1_APROV:="B"
//	MsUnlock()     


// inicio             
cNumSC := SC1->C1_NUM
cQuery := " UPDATE "+RETSQLNAME("SC1")                                
cQuery += " SET C1_APROV = 'B' "
cQuery += " WHERE C1_NUM = '"+cNumSC+"'  AND C1_FILIAL = '" + XFILIAL("SC1") + "' AND D_E_L_E_T_ = ' ' "

TcSqlExec(cQuery)
//TCREFRESH(RetSqlName("SC1"))


//fim
EndIf

RestArea(aArea)

Return .T.
