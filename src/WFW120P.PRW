#INCLUDE "PROTHEUS.CH"
#include "rwmake.ch"
#include "TbiConn.ch"
#include "TbiCode.ch"    
/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³MT120WF   ºAutor  ³ON LINE  - JULIANO º Data ³  12/08/11   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³Ponto de entrada para envio de Workflow na cotacao de com-  º±±
±±º          ³pras.                                                       º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ SIGACOM                       	                          º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
USER function MT120WF(nOpcao,oProcess)  
	If ValType(nOpcao) = "A"
	   nOpcao := nOpcao[1]
	Endif
	If nOpcao == NIL
	   nOpcao :=0
	Endif
	cstatus 	:= 0
	If oProcess == NIL
		oProcess := TWFProcess():New( "PEDCOM", "Pedido de Compras" )
	Endif	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Declaracao de variaveis utilizadas no programa atraves da funcao    ³
	//³ SetPrvt, que criara somente as variaveis definidas pelo usuario,    ³
	//³ identificando as variaveis publicas do sistema utilizadas no codigo ³
	//³ Incluido pelo assistente de conversao do AP5 IDE                    ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	SetPrvt("CPAR,NBARRA,N_ITEM,C_MAT,C_DEST,CGRAP")
	SetPrvt("C_NUM,C_MOTIVO,N_TOTPC,CGRAPANT,N_TERMINA,N_DOHTML")
	SetPrvt("CRAIZ,NRET,NHLDHTM,NHLDSCP,CIND,C_PCANT")
	SetPrvt("N_QTDPC,N_FRTPC,A_ITENS,LCABEC,_AREGISTROS,NLIMITE")
	SetPrvt("CAB_NUM,CAB_EMIS,CAB_FORN,CAB_COND,CAB_NOME,_NI")
	SetPrvt("ARRAYCAB,ARRAYITENS,C_ITPED,NPRESUP,CAPROV,AINFO")
	SetPrvt("CMAILAP,CNOMEAP,CORIGEM,CABEC,NHDLVLR,NCOUNT")
	SetPrvt("NRESULT,CHTML,NHDLCONNECT")
	SetPrvt("lPrimeira")
	lPrimeira := .F.
	Do Case
		Case nOpcao == 0
		MsgRun("Enviando Workflow Aprovação Pedido de Compras, Aguarde...","",{|| CursorWait(), MT120WFi( oProcess,lPrimeira ),CursorArrow()})
		Case nOpcao == 1
		MT120WFr( oProcess,lPrimeira )
		Case nOpcao == 2
		MT120WFt( oProcess )
	EndCase       
	oProcess:Free()
RETURN()


Static Function MT120WFi( oProcess, lPrimeira )

	Local cStrAprov	:=""
	Local cChave	:=""          
	Local cMailSup  :=""
	local cont      :=0 
	local i
	
	Private	aInfo   :=""
	Private cMailAp :=""
	Private	cNomeAP :=""               
	Private cAprov  :=""
	Private comprador:=""
	Private cNum    :=SC7->C7_NUM
	
	Private cMailRp :=""
	Private cQryApr :="" 
	Private TRBAPR	:=""
	Private cMailAp_:="" 
	Private cCodAprs:="" 
	Private cCodApr :="" 	
	Private cCodMail:={} 
	
	If oProcess == NIL
		oProcess := TWFProcess():New( "PEDCOM", "Pedido de Compras" )
	Endif

	//Pega o codigo dos aprovadores, o e-mail e o valor do pedido de compra
	cQryApr := " SELECT * FROM SCR010 WHERE D_E_L_E_T_ = ' ' AND SCR010.CR_NUM = '"+cNum+"' "
	dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQryApr),"TRBAPR", .F., .T.) 
	TRBAPR->(dbGoTop()) 

	if TRBAPR->CR_TOTAL >= 80000  // Pedido >= 80000,00 
        
		// Pega o codigo de todos aprovadores do pedido
		While !TRBAPR->(EOF())
			cCodAprs += TRBAPR->CR_USER + '|'
			aadd(cCodMail, TRBAPR->CR_USER)
			TRBAPR->(dbSkip())
		Enddo  
		
		//Se o pedito tiver origem em uma solicitacao de compra
		IF !EMPTY(SC7->C7_NUMSC)

			msgalert('Pedido acima de R$ 80.000,00, e-mail de aprovação enviado para todos os diretores.')				 
			//Pegar o codigo do aprovador da solicitacao de compra e verifica se ele esta dentro dos aprovadores do pedido
			cCodApr := SC1->C1_CODAPRO
			if !(cCodApr $ cCodAprs)
				cMailRp := alltrim(UsrRetMail(cCodApr)) + ';'
			endif

		//Caso o pedido seja lancado diretamente
		ELSE

			msgalert('Pedido acima de R$ 80.000,00, e-mail de aprovação enviado para todos os diretores.')		
			//Pegar o codigo do usuario que incluiu o pedido e verifica se ele esta dentro dos aprovadores do pedido
			cCodApr := SC7->C7_USER
			if !(cCodApr $ cCodAprs)
				cMailRp := alltrim(UsrRetMail(cCodApr)) + ';'
			endif
		
		ENDIF
		
	else // Pedido < 80000,00 
	
		//Pega o codigo dos aprovadores
		While !TRBAPR->(EOF())
			cCodAprs += TRBAPR->CR_USER + '|'
			TRBAPR->(dbSkip())
		Enddo 
		
		//Se o pedido tiver origem em uma solicitacao de compra
		IF !EMPTY(SC7->C7_NUMSC) 
			
			//Pegar o codigo do aprovador da solicitacao de compra 
			cCodApr := SC1->C1_CODAPRO
			
			//Se o aprovador da SC pertence ao grupo de aprovadores do pedido 
			if cCodApr $ cCodAprs 
				aadd(cCodMail, cCodApr)
			else
			
				cMailRp := alltrim(UsrRetMail(cCodApr)) + ';'
				DBSELECTAREA("SAK")
				DBSETORDER(2)
				DBSEEK(XFILIAL("SAK")+cCodApr)
				cCodApr := SAK->AK_APROSUP
				DBSETORDER(1)
				DBSEEK(XFILIAL("SAK")+cCodApr)
				
				//Pegar o codigo do superior do aprovador da SC
				cCodApr := SAK->AK_USER  
		
				//Se o superior pertence ao grupo de aprovadores do pedido
				if cCodApr $ cCodAprs 
					aadd(cCodMail, cCodApr)
				else
					for cont:= 1 to 5
						cMailRp += alltrim(UsrRetMail(cCodApr)) + ';'
						cCodApr := SAK->AK_APROSUP
						DBSETORDER(1)
						DBSEEK(XFILIAL("SAK")+cCodApr)
						
						//Pegar o codigo do superior				
						cCodApr := SAK->AK_USER
		
						//Se o superior pertence ao grupo de aprovadores do pedido
						if cCodApr $ cCodAprs 
							aadd(cCodMail, cCodApr)
							cont := 5
						endif
					next
				endif
			endif
			
		//Caso o pedido seja lancado diretamente
		ELSE

			// Seleciona o Aprovador		
			Private cCodApr  := Space(6)
			Private nOpca    := 1 
			Private oDlg     
			TRBAPR->(dbGoTop()) 
			
			DEFINE MSDIALOG oDlg TITLE "Aprovadores" FROM 33,25 TO 300,410 PIXEL  //"Config. Parametros"
				@ 001,005 	TO 130, 185 OF oDlg PIXEL
				@ 004,008 	SAY "Selecione o aprovador:" SIZE 90, 7 OF oDlg PIXEL  
				@ 004,096 	MSGET oCodApr Var cCodApr Picture "@!" F3 "UNISAK" SIZE 50,10 OF oDlg PIXEL 
														
				DEFINE SBUTTON FROM 05, 156 TYPE 1 ACTION (nOpca := 1,oDlg:End())ENABLE OF oDlg
			ACTIVATE MSDIALOG oDlg CENTERED ON INIT (nOpca := 0, .T.)	// Zero nOpca caso    
			
			if cCodApr $ cCodAprs 
				aadd(cCodMail, cCodApr)
			endif
			
/*			//Pegar o codigo do usuario que incluiu o pedido 
			cCodApr := SC7->C7_USER
			
			//Se o usuario pertence ao grupo de aprovadores do pedido 
			if cCodApr $ cCodAprs 
				cMailAp := alltrim(UsrRetMail(cCodApr)) + ';'
			else
				cMailRp := alltrim(UsrRetMail(cCodApr)) + ';'
				cCodApr := substr(PswRet()[1][11],1,6)

				//Se o superior pertence ao grupo de aprovadores do pedido
				if cCodApr $ cCodAprs 

	                // Envia e-mail para todos os superiores
					Private cAprov     := ""
					Private cAprovIni  := PswRet()[1][11]                      
					Private nPoscAprov := 1 
					
					cAprov:=Substr(cAprovIni,1,6)
					while cAprov $ cAprovIni
					      nPoscAprov += 7
					      cMailAp    += rtrim(UsrRetMail(cAprov))  
					      cAprov     := Substr(cAprovIni,nPoscAprov,6)
					      if cAprov $ cAprovIni
					      	cMailAp +=";" 
					      endif	   
					enddo  
					
				else
					DBSELECTAREA("SAK")
					DBSETORDER(2)
					DBSEEK(XFILIAL("SAK")+cCodApr)
					
					for cont:= 1 to 5
						cMailRp += alltrim(UsrRetMail(cCodApr)) + ';'
						cCodApr := SAK->AK_APROSUP
						DBSETORDER(1)
						DBSEEK(XFILIAL("SAK")+cCodApr)
						
						//Pegar o codigo do superior				
						cCodApr := SAK->AK_USER
		
						//Se o superior pertence ao grupo de aprovadores do pedido
						if cCodApr $ cCodAprs 
							cMailAp := alltrim(UsrRetMail(cCodApr)) + ';'
							cont := 5
						endif
					next
				endif
			endif*/

		ENDIF
		
	endif 

	If !empty(cMailRp)
		Private cMailBox := AllTrim(WFGetMV( "MV_WFMLBOX", "" ))
		Private cTo      := cMailRp
		Private oMail    := TWFMail():New()
		Private oMailBox := oMail:GetMailBox( cMailBox )
		Private cHtml    := ""
		Private cSubject := "APROVACAO DO PEDIDO "+SC7->C7_NUM+" ESTA ACIMA DA SUA ALCADA."
		Private cBody    := "O PEDIDO "+SC7->C7_NUM+" ESTA ACIMA DA SUA ALCADA, E JA FOI ENCAMINHADO PARA O APROVADOR COM A ALCADA PARA ESTE PEDIDO."
		Private aAttachs := {}
		oMailBox:NewMessage( cTo,,, cSubject, cBody, aAttachs )
		oMailBox:Send()
	endif

	If len(cCodMail) > 0
		for i:=1 to len(cCodMail)
			cMailAp := alltrim(UsrRetMail(cCodMail[i]))
			cMailAp_+= alltrim(UsrRetMail(cCodMail[i]))+ ' ; '
			MT120WFa(oProcess, cCodMail[i])
		next
		Msginfo("E-mail de aprovação do PC enviado para: "+cMailAp_)
	else
		Msginfo("Erro no cadastro de aprovadores, nenhum e-mail foi enviado. O pedido deve ser aprovado via Protheus.")
	endif
	TRBAPR->(DBCLOSEAREA())
	
Return()

Static Function MT120WFa(oProcess, cCdAp_)
	Local cMvAtt := GetMv("MV_WFHTML")
	Local cAprov := cCdAp_
	Local cMailSup := UsrRetMail(cAprov)
	Local aMeses	:= {"Jan","Fev","Mar","Abr","Mai","Jun","Jul","Ago","Set","Out","Nov","Dez"}
	Local aCond:={},nTotal := 0
	Local cDiasA
	Local cDiasE
	Local oHtml

	If oProcess == NIL
		oProcess := TWFProcess():New( "PEDCOM", "Pedido de Compras" )
	Endif

	cDiasA := SubStr(GetMv("MV__TIMESC"),1,2) //TIMEOUT Dias para Avisar Aprovador
	cDiasE := SubStr(GetMv("MV__TIMESC"),3,2) //TIMEOUT Dias para Excluir o Pedido
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Muda o parametro para enviar no corpo do e-mail³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	PutMv("MV_WFHTML","T")
	oProcess := TWFProcess():New( "PEDCOM", "Pedido de Compras" )
	oProcess:NewTask( "Solicitação", "\workflow\htm\mt120wf1.htm" )
	oProcess:cSubject := "Solicitacao Pedido de Compra"
	//	oProcess:bReturn := "u_MT120WF( 1 )"
	oHTML := oProcess:oHTML
	/*** Preenche os dados do cabecalho ***/
	oHtml:ValByName( "EMISSAO", SC7->C7_EMISSAO )
	oHtml:ValByName( "FORNECEDOR", SC7->C7_FORNECE )
	oHtml:ValByName( "lb_nome", SA2->A2_NOME )
	//Pego as condiicoes de Pagamento
	dbSelectArea('SE4')
	DBSETORDER(1)
	dbSeek(xFilial('SE4') + SC7->C7_COND)
	ccond := SE4->E4_DESCRI
	oHtml:ValByName( "lb_cond", CCOND ) 
	dbSelectArea('SC7')
	dbSetOrder(1)
	dbSeek(xFilial('SC7')+cNum)
	oHtml:ValByName( "PEDIDO", SC7->C7_NUM )
	PswOrder(1)
	If PswSeek(SC7->C7_USER,.t.)
		aInfo   	:= PswRet(1)
	    comprador   := alltrim(aInfo[1,4])
	Endif	
	oHtml:ValByName( "comprador", comprador )
	oHtml:ValByName( "cAprov", cAprov )
	oHtml:ValByName( "cMailap", cMailap )
	oProcess:fDesc := "Pedido de Compras No "+ cNum
	oHtml:ValByName("its.Item"			,{})
	oHtml:ValByName("its.CodProd"		,{})
	oHtml:ValByName("its.Desc"			,{})
	oHtml:ValByName("its.SaldoAtu"		,{})
	oHtml:ValByName("its.EstMin"		,{})
	oHtml:ValByName("its.QuantSol"		,{})
	oHtml:ValByName("its.UM"			,{})
	oHtml:ValByName("its.Local"			,{})
	oHtml:ValByName("its.QuantEmb"		,{})
	oHtml:ValByName("its.UPRC"			,{})
	oHtml:ValByName("its.Lead"			,{})
	oHtml:ValByName("its.DataNec"		,{})
	oHtml:ValByName("its.DataCom"		,{})
	oHtml:ValByName("its.Obs"			,{})
	While !Eof() .and. SC7->C7_FILIAL+SC7->C7_NUM == xFilial('SC7')+cNum
		nTotal := nTotal + C7_TOTAL
		AAdd( (oHtml:ValByName( "it.item" )),C7_ITEM )
		AAdd( (oHtml:ValByName( "it.codigo" )),C7_PRODUTO )
		AAdd( (oHtml:ValByName( "it.quant" )),TRANSFORM( C7_QUANT,'@E 999,999.99' ) )
		AAdd( (oHtml:ValByName( "it.observ" )),C7_OBS )
		AAdd( (oHtml:ValByName( "it.preco" )),TRANSFORM( C7_PRECO,'@E 999,999.99' ) )
		AAdd( (oHtml:ValByName( "it.total" )),TRANSFORM( C7_TOTAL,'@E 999,999.99' ) )
		aadd((oHtml:ValByName("its.Item"))			, C7_ITEM		   		) 
		aadd((oHtml:ValByName("its.CodProd"))		, C7_PRODUTO	   		) //Cod Produto
		dbSelectArea('SB1')
		dbSetOrder(1)
		dbSeek(xFilial('SB1')+SC7->C7_PRODUTO)
		AAdd( (oHtml:ValByName( "it.descricao" )),SB1->B1_DESC )
		AAdd( (oHtml:ValByName( "it.unid" )),SB1->B1_UM ) 
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Saldos em Estoque³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		aadd((oHtml:ValByName("its.Desc"))			, SB1->B1_DESC)
		aadd((oHtml:ValByName("its.SaldoAtu"))		, TRANSFORM(SB2->B2_QATU, PesqPict("SB2","B2_QATU" ,12))	) //Saldo Atual Estoque
		aadd((oHtml:ValByName("its.EstMin"))			, TRANSFORM(SB1->B1_EMIN		, PesqPict("SB1","B1_EMIN" ,12))	) //Ponto de Pedido
		aadd((oHtml:ValByName("its.QuantSol"))		, TRANSFORM(SC7->C7_QUANT - SC7->C7_QUJE , PesqPict("SC7","C7_QUANT",12))) //Saldo da Solicitacao
		aadd((oHtml:ValByName("its.UM"))				, TRANSFORM(SC7->C7_UM			, PesqPict("SC7","C7_UM"))			) //Unidade de Medida
		aadd((oHtml:ValByName("its.Local"))			, TRANSFORM(SC7->C7_LOCAL		, PesqPict("SC7","C7_LOCAL"))		) //Armazem da Solicitacao
		aadd((oHtml:ValByName("its.QuantEmb"))		, TRANSFORM(SB1->B1_QE			, PesqPict("SB1","B1_QE"   ,09))	) //Quantidade Por Embalagem
		aadd((oHtml:ValByName("its.UPRC"))			, TRANSFORM(SB1->B1_UPRC		, PesqPict("SB1","B1_UPRC",12))		) //Ultimo Preco de Compra
		aadd((oHtml:ValByName("its.Lead"))			, TRANSFORM(CalcPrazo(SC7->C7_PRODUTO,SC7->C7_QUANT), "999")		) //Lead Time
		aadd((oHtml:ValByName("its.DataNec"))			, If(Empty(SC7->C7_DATPRF),SC7->C7_EMISSAO,SC7->C7_DATPRF)			)//Data da Necessidade
		aadd((oHtml:ValByName("its.DataCom"))			, SomaPrazo(If(Empty(SC7->C7_DATPRF),SC7->C7_EMISSAO,SC7->C7_DATPRF), -CalcPrazo(SC7->C7_PRODUTO,SC7->C7_QUANT)))// Data para Comprar
		aadd((oHtml:ValByName("its.Obs"))				, TRANSFORM(SC7->C7_OBS , "@!")										) //Observacao da Cotacao							
		DbSelectArea('SC7')
		RecLock('SC7')
		C7_WFID := oProcess:fProcessID
		C7_FILENT := C7_FILIAL
		MsUnlock()
		dbSkip()
	Enddo
	oHtml:ValByName( "lbValor" ,TRANSFORM( nTotal,'@E 999,999.99' ) )
	oHtml:ValByName( "lbFrete" ,TRANSFORM( 0,'@E 999,999.99' ) )
	oHtml:ValByName( "lbTotal" ,TRANSFORM( nTotal,'@E 999,999.99' ) )
	oHtml:valByName('botoes', '<input type=submit name=B1 value=Enviar> <input type=reset name=B2 value=Limpar>')
	cQuery := " SELECT SC8.*,SCE.*,A2_NOME,C1_FILIAL, C1_NUM, C1_EMISSAO, C1_SOLICIT, C1_ITEM, C1_PRODUTO, C1_DESCRI, C1_UM, C1_QUANT, C1_DATPRF, C1_OBS, C1_CC, C1_CODAPRO, C1_QUJE, C1_LOCAL, CTT_DESC01,"
	cQuery += " B2_QATU, B1_EMIN, B1_QE, B1_UPRC, B1_DESC "
	cQuery += " FROM "+RetSqlName('SC8')+" SC8 "
	cQuery += " LEFT JOIN "+RetSqlname('SCE')+" SCE ON C8_NUM = CE_NUMCOT AND C8_FILIAL = '" + XFILIAL("SCE") + "' AND SCE.D_E_L_E_T_ = ' ' "
	cQuery += " LEFT JOIN "+RetSqlName('SC1')+" SC1 ON C8_NUMSC = C1_NUM AND C8_FILIAL = '" + XFILIAL("SC1") + "' AND SC1.D_E_L_E_T_ = ' ' "   
	cQuery += " LEFT JOIN "+RetSqlName('SA2')+" SA2 ON A2_COD = C8_FORNECE AND A2_LOJA = C8_LOJA AND C8_FILIAL = '" + XFILIAL("SC8") + "' AND SA2.D_E_L_E_T_ = ' ' "
	cQuery += " LEFT JOIN "+RetSqlName('CTT')+" CTT ON C1_CC = CTT_CUSTO"
	cQuery += " LEFT JOIN "+RetSqlname('SB2')+" SB2 ON C8_PRODUTO = B2_COD AND C1_LOCAL = B2_LOCAL"
	cQuery += " LEFT JOIN "+RetSqlName('SB1')+" SB1 ON C8_PRODUTO = B1_COD"
	cQuery += " WHERE C8_NUM = '"+SC8->C8_NUM+"' AND C8_FILIAL = '" + XFILIAL("SC8") + "' AND SC8.D_E_L_E_T_ = ' ' "
	cQuery += " AND C8_ITEM = '"+SC8->C8_ITEM+"'"
	dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQuery),"TRBD", .F., .T.)
	TcSetField("TRBD","C8_EMISSAO","D")
	TcSetField("TRBD","C8_DATPRF","D")
    TcSetField("TRBD","C1_EMISSAO","D")
	TcSetField("TRBD","C1_DATPRF","D")

	dbSelectArea("TRBD")
	TRBD->(dbGoTop())
//	cNumSc		:= TRBD->C1_NUM
//	cSolicit	:= TRBD->C1_SOLICIT
//	cItem		:= TRBD->C1_ITEM
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Dados do Cabecalho³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	oHtml:ValByName("diasA"			, cDiasA)
	oHtml:ValByName("diasE"			, cDiasE)
	oHtml:ValByName("Num"		, TRBD->C8_NUM				) //Numero da Cotacao
	oHtml:ValByName("Item1"		, TRBD->C8_ITEM 				) //Item Cotacao
	//	oHtml:ValByName("CC"		, TRBD->C1_CC				) //Centro de Custo
	//	oHtml:ValByName("DescCC"	, TRBD->CTT_DESC01			) //Descricao Centro de Custo
	//	oHtml:ValByName("Req"	  	, TRBD->C1_SOLICIT			) //Nome Requisitante
	//	oHtml:ValByName("Emissao"	, DTOC(TRBD->C1_EMISSAO)		) //Data de Emissao Solicitacao
	//oHtml:ValByName("cAPROV"	, ""						) //Variavel que Retorna "Aprovado / Rejeitado"
	//oHtml:ValByName("cMOTIVO"	, ""						) //Variavel que Retorna o Motivo da Rejeicao       
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Cotações de Pedidos de Compra ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	oHtml:ValByName("itc.NumP"			, {})
	oHtml:ValByName("itc.ItemP"			, {})
	oHtml:ValByName("itc.CodP"			, {})
	oHtml:ValByName("itc.LjP"			, {})
	oHtml:ValByName("itc.NomeP"			, {})
	oHtml:ValByName("itc.QtdeP"			, {})
	oHtml:ValByName("itc.UMP"			, {})
	oHtml:ValByName("itc.VlrUnP"		, {})
	oHtml:ValByName("itc.VlrTotP"		, {})
	oHtml:ValByName("itc.EmiP"			, {})
	oHtml:ValByName("itc.NecP"			, {})
	oHtml:ValByName("itc.PraP"			, {})
	oHtml:ValByName("itc.CondP"			, {}) 
	oHtml:ValByName("itc.Motfecha"      , {}) 
	oHtml:ValByName("itc.Motivo"		, {})                                                	

	If !TRBD->(EOF())  // 4 if
//		dbSelectArea("TRBD")
//		TRBD->(dbGoTop())
		//		nContador := 0
		While !TRBD->(EOF())
		//			nContador++
		//			If nContador > 03 //Numero de Cotações
		//				Exit
		//			EndIf   
			aadd(oHtml:ValByName("itc.NumP")		, TRBD->C8_NUMPED		)
			aadd(oHtml:ValByName("itc.ItemP")		, TRBD->C8_ITEMPED		)
			aadd(oHtml:ValByName("itc.CodP")		, TRBD->C8_FORNECE	)
			aadd(oHtml:ValByName("itc.LjP")			, TRBD->C8_LOJA		)
			aadd(oHtml:ValByName("itc.NomeP")		, TRBD->A2_NOME		)
			aadd(oHtml:ValByName("itc.QtdeP")		, TRANSFORM(TRBD->C8_QUANT , PesqPict("SC8","C8_QUANT",14))	)
			aadd(oHtml:ValByName("itc.UMP")			, TRBD->C8_UM		)
			aadd(oHtml:ValByName("itc.VlrUnP")		, TRANSFORM(TRBD->C8_PRECO, PesqPict("SC8","c8_preco",14))	)
			aadd(oHtml:ValByName("itc.VlrTotP")		, TRANSFORM(TRBD->C8_TOTAL, PesqPict("SC8","c8_total",14))	)
			aadd(oHtml:ValByName("itc.EmiP")		, DTOC(TRBD->C8_EMISSAO))
			aadd(oHtml:ValByName("itc.NecP")		, DTOC(TRBD->C8_DATPRF)	)
			aadd(oHtml:ValByName("itc.PraP")		, TRANSFORM(Val(DTOC(TRBD->C8_DATPRF))-Val(DTOC(TRBD->C8_EMISSAO)), "999"))
			aadd(oHtml:ValByName("itc.CondP")		, TRBD->C8_COND		)
			aadd(oHtml:ValByName("itc.Motfecha")	, If("AUTOMATICAMENTE"$TRBD->C8_MOTIVO,'Sim','Não'))
			aadd(oHtml:ValByName("itc.Motivo")		, If(Empty(TRBD->C8_MOTIVO),'Não informado',If("AUTOMATICAMENTE"$TRBD->C8_MOTIVO,'ESCOLHIDO PELO SISTEMA',TRBD->C8_MOTIVO)))
			TRBD->(dbSkip())
		End         
  	Else //Caso nao tenha dados   // 4 if                    
		aadd(oHtml:ValByName("itc.NumP")			, "")
		aadd(oHtml:ValByName("itc.ItemP")		, "")
		aadd(oHtml:ValByName("itc.CodP")			, "")
		aadd(oHtml:ValByName("itc.LjP")			, "")
		aadd(oHtml:ValByName("itc.NomeP")		, "")
		aadd(oHtml:ValByName("itc.QtdeP")		, "")
		aadd(oHtml:ValByName("itc.UMP")			, "")
		aadd(oHtml:ValByName("itc.VlrUnP")		, "")
		aadd(oHtml:ValByName("itc.VlrTotP")		, "")
		aadd(oHtml:ValByName("itc.EmiP")			, "")
		aadd(oHtml:ValByName("itc.NecP")			, "")
		aadd(oHtml:ValByName("itc.PraP")			, "")
		aadd(oHtml:ValByName("itc.CondP")		, "")
		aadd(oHtml:ValByName("itc.Motfecha")		, "") 
		aadd(oHtml:ValByName("itc.Motivo")		, "")                                                
	EndIf                                // 4 if

/*

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Consumo Ultimos 12 Meses³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	//Query busca Consumo do produto
	cQuery2 := " SELECT *"
	cQuery2 += " FROM "+RetSqlName('SB3')+" SB3"
	cQuery2 += " WHERE B3_COD = '"+SC7->C7_PRODUTO+"'"
	cQuery2 += " AND D_E_L_E_T_ <> '*'"
	dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQuery2),"TRBD2", .F., .T.)
	If !TRBD2->(EOF())      // 3 if
		dbSelectArea("TRBD2")
		TRBD2->(dbGoTop())
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
			cCampos := "TRBD2->B3_Q"+cMes
			oHtml:ValByName("CMes"+AllTrim(Str(j))	, TRANSFORM(&cCampos , PesqPict("SB3","B3_Q01",9))) //Valor de Consumo nos Meses
		Next j
		oHtml:ValByName("MedC"		, TRANSFORM(TRBD2->B3_MEDIA, PesqPict("SB3","B3_MEDIA",8))) //Media de Consumo
	Else //Caso nao tenha dados    // 3 if
		oHtml:ValByName("MedC"		, "")
		For m := 1 To 12
			oHtml:ValByName("CMes"+AllTrim(Str(m))	, "")
			oHtml:ValByName("Mes"+AllTrim(Str(m))	, "")
		Next m
	EndIf      // 3 if
	TRBD2->(dbCloseArea())
	
//*******************aqui
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Ultimos Pedidos de Compra ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	oHtml:ValByName("it0.NumP"			, {})
	oHtml:ValByName("it0.ItemP"			, {})
	oHtml:ValByName("it0.CodP"			, {})
	oHtml:ValByName("it0.LjP"			, {})
	oHtml:ValByName("it0.NomeP"			, {})
	oHtml:ValByName("it0.QtdeP"			, {})
	oHtml:ValByName("it0.UMP"			, {})
	oHtml:ValByName("it0.VlrUnP"		, {})
	oHtml:ValByName("it0.VlrTotP"		, {})
	oHtml:ValByName("it0.EmiP"			, {})
	oHtml:ValByName("it0.NecP"			, {})
	oHtml:ValByName("it0.PraP"			, {})
	oHtml:ValByName("it0.CondP"			, {})
	oHtml:ValByName("it0.QtdeEntP"		, {})
	oHtml:ValByName("it0.SalP"			, {})
	oHtml:ValByName("it0.EliP"			, {})
	//Query busca Pedidos do Produto
	cQuery3 := " SELECT C7_NUM, C7_ITEM, C7_FORNECE, C7_LOJA, A2_NOME, C7_QUANT, C7_UM, C7_PRECO, C7_TOTAL, C7_EMISSAO, C7_DATPRF, C7_COND, C7_QUJE, C7_RESIDUO"
	cQuery3 += " FROM "+RetSqlName('SC7')+" C7"
	cQuery3 += " INNER JOIN "+RetSqlName('SA2')+" A2 ON A2_COD = C7_FORNECE AND A2_LOJA = C7_LOJA"
	cQuery3 += " WHERE C7_FILIAL = '"+SC7->C7_FILIAL+"' AND C7_PRODUTO = '"+SC7->C7_PRODUTO+"'"
	cQuery3 += " AND C7.D_E_L_E_T_ <> '*'"
	cQuery3 += " AND A2.D_E_L_E_T_ <> '*'"
	cQuery3 += " ORDER BY C7_EMISSAO DESC"
	dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQuery3),"TRBD3", .F., .T.)
	TcSetField("TRBD3","C7_EMISSAO","D")
	TcSetField("TRBD3","C7_DATPRF","D")
	If !TRBD3->(EOF())  // 4 if
		dbSelectArea("TRBD3")
		TRBD3->(dbGoTop())
		nContador := 0
		While !TRBD3->(EOF())
			nContador++
			If nContador > 03 //Numero de Pedidos
				Exit
			EndIf
			aadd(oHtml:ValByName("it0.NumP")			, TRBD3->C7_NUM		)
			aadd(oHtml:ValByName("it0.ItemP")		, TRBD3->C7_ITEM		)
			aadd(oHtml:ValByName("it0.CodP")			, TRBD3->C7_FORNECE	)
			aadd(oHtml:ValByName("it0.LjP")			, TRBD3->C7_LOJA		)
			aadd(oHtml:ValByName("it0.NomeP")		, TRBD3->A2_NOME		)
			aadd(oHtml:ValByName("it0.QtdeP")		, TRANSFORM(TRBD3->C7_QUANT , PesqPict("SC7","C7_QUANT",14))	)
			aadd(oHtml:ValByName("it0.UMP")			, TRBD3->C7_UM		)
			aadd(oHtml:ValByName("it0.VlrUnP")		, TRANSFORM(TRBD3->C7_PRECO, PesqPict("SC7","c7_preco",14))	)
			aadd(oHtml:ValByName("it0.VlrTotP")		, TRANSFORM(TRBD3->C7_TOTAL, PesqPict("SC7","c7_total",14))	)
			aadd(oHtml:ValByName("it0.EmiP")			, DTOC(TRBD3->C7_EMISSAO))
			aadd(oHtml:ValByName("it0.NecP")			, DTOC(TRBD3->C7_DATPRF)	)
			aadd(oHtml:ValByName("it0.PraP")			, TRANSFORM(Val(DTOC(TRBD3->C7_DATPRF))-Val(DTOC(TRBD3->C7_EMISSAO)), "999"))
			aadd(oHtml:ValByName("it0.CondP")		, TRBD3->C7_COND		)
			aadd(oHtml:ValByName("it0.QtdeEntP")		, TRANSFORM(TRBD3->C7_QUJE, PesqPict("SC7","C7_QUJE",14))		)
			aadd(oHtml:ValByName("it0.SalP")			, TRANSFORM(If(Empty(TRBD3->C7_RESIDUO),TRBD3->C7_QUANT-TRBD3->C7_QUJE,0), PesqPict("SC7","C7_QUJE",14)))
			aadd(oHtml:ValByName("it0.EliP")			, If(Empty(TRBD3->C7_RESIDUO),'Não','Sim'))
			TRBD3->(dbSkip())
		End
	Else //Caso nao tenha dados   // 4 if
		aadd(oHtml:ValByName("it0.NumP")			, "")
		aadd(oHtml:ValByName("it0.ItemP")		, "")
		aadd(oHtml:ValByName("it0.CodP")			, "")
		aadd(oHtml:ValByName("it0.LjP")			, "")
		aadd(oHtml:ValByName("it0.NomeP")		, "")
		aadd(oHtml:ValByName("it0.QtdeP")		, "")
		aadd(oHtml:ValByName("it0.UMP")			, "")
		aadd(oHtml:ValByName("it0.VlrUnP")		, "")
		aadd(oHtml:ValByName("it0.VlrTotP")		, "")
		aadd(oHtml:ValByName("it0.EmiP")			, "")
		aadd(oHtml:ValByName("it0.NecP")			, "")
		aadd(oHtml:ValByName("it0.PraP")			, "")
		aadd(oHtml:ValByName("it0.CondP")		, "")
		aadd(oHtml:ValByName("it0.QtdeEntP")		, "")
		aadd(oHtml:ValByName("it0.SalP")			, "")
		aadd(oHtml:ValByName("it0.EliP")			, "")
	EndIf                                // 4 if
	TRBD3->(dbCloseArea())
	*/
		//TRBD->(dbCloseArea())
	/*
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
	Endif	
	cQuery1 += " WHERE D4_COD = '"+TRBD->C1_PRODUTO+"'"
	cQuery1 += " AND D4_QUANT > 0"
	cQuery1 += " AND D4.D_E_L_E_T_ <> '*'"
	cQuery1 += " AND C2.D_E_L_E_T_ <> '*'"
	cQuery1 += " ORDER BY D4_DATA"
	dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQuery1),"TRBD1", .F., .T.)
	TcSetField("TRBD1","D4_DATA","D")
	If !TRBD1->(EOF()) // 2 if
		dbSelectArea("TRBD1")
		TRBD1->(dbGoTop())
		While !EOF()
			aadd(oHtml:ValByName("op1.OP")		, TRBD1->D4_OP			) //Numero da OP 1
			aadd(oHtml:ValByName("op1.Prod")	, TRBD1->C2_PRODUTO		) //Produto a Ser Produzido OP 1
			aadd(oHtml:ValByName("op1.Ini")		, DTOC(TRBD1->D4_DATA)	) //Data da OP 1
			aadd(oHtml:ValByName("op1.QtdOp")	, TRANSFORM(TRBD1->D4_QUANT , PesqPict("SD4","D4_QUANT",12))	) //Quantidade OP 1
			TRBD1->(dbSkip())
			aadd(oHtml:ValByName("op2.OP")		, TRBD1->D4_OP			) //Numero da OP 2
			aadd(oHtml:ValByName("op2.Prod")	, TRBD1->C2_PRODUTO		) //Produto a Ser Produzido OP 2
			aadd(oHtml:ValByName("op2.Ini")		, DTOC(TRBD1->D4_DATA)	) //Data da OP 2
			aadd(oHtml:ValByName("op2.QtdOp")	, TRANSFORM(TRBD1->D4_QUANT , PesqPict("SD4","D4_QUANT",12))	) //Quantidade OP 2
			TRBD1->(dbSkip())
			aadd(oHtml:ValByName("op3.OP")		, TRBD1->D4_OP			) //Numero da OP 3
			aadd(oHtml:ValByName("op3.Prod")	, TRBD1->C2_PRODUTO		) //Produto a Ser Produzido OP 3
			aadd(oHtml:ValByName("op3.Ini")		, DTOC(TRBD1->D4_DATA)	) //Data da OP 3
			aadd(oHtml:ValByName("op3.QtdOp")	, TRANSFORM(TRBD1->D4_QUANT , PesqPict("SD4","D4_QUANT",12))	) //Quantidade OP 3
			TRBD1->(dbSkip())
		End
	Else // 2 if
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
	EndIf  // 2 if
	TRBD1->(dbCloseArea())
	*/

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
	If mv_par03 == 1 // Amarracao por Produto      5 if
		//Query busca Fornecedores do Produto
		cQuery4 := " SELECT A5_FORNECE, A5_LOJA, A2_NOME, A2_TEL, A2_CONTATO, A2_FAX, A2_ULTCOM, A2_MUN, A2_EST, A2_RISCO, A5_CODPRF"
		cQuery4 += " FROM "+RetSqlName('SA5')+" A5"
		cQuery4 += " INNER JOIN "+RetSqlName('SA2')+" A2 ON A5_FORNECE = A2_COD AND A5_LOJA = A2_LOJA"
		cQuery4 += " WHERE A5_PRODUTO = '"+TRBD->C1_PRODUTO+"'"
		cQuery4 += " AND A5.D_E_L_E_T_ <> '*'"
		cQuery4 += " AND A2.D_E_L_E_T_ <> '*'"
		cQuery4 += " order by  A2_ULTCOM DESC"
		dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQuery4),"TRBD4", .F., .T.)
		TcSetField("TRBD4","A2_ULTCOM","D")
		If !TRBD4->(EOF())                              // 6 if
			dbSelectArea("TRBD4")
			TRBD4->(dbGoTop())
			nContador := 0
			While !TRBD4->(EOF())
				nContador++
				If nContador > 03 //Numero de Fornecedores
					Exit
				EndIf
				aadd(oHtml:ValByName("it1.CodF")		, TRBD4->A5_FORNECE	) //Codigo do Fornecedor
				aadd(oHtml:ValByName("it1.LjF")			, TRBD4->A5_LOJA		) //Codigo da Loja
				aadd(oHtml:ValByName("it1.NomeF")		, TRBD4->A2_NOME		) //Nome do Fornecedor
				aadd(oHtml:ValByName("it1.TelF")		, TRBD4->A2_TEL		) //Telefone do Fornecedor
				aadd(oHtml:ValByName("it1.ContF")		, TRBD4->A2_CONTATO	) //Contato no Fornecedor
				aadd(oHtml:ValByName("it1.FaxF")		, TRBD4->A2_FAX		) //Fax no Fornecedor
				aadd(oHtml:ValByName("it1.UlComF")		, DTOC(TRBD4->A2_ULTCOM)	) //Ultima Compra com o Fornecedor
				aadd(oHtml:ValByName("it1.MunicF")		, TRBD4->A2_MUN		) //Municipio do Fornecedor
				aadd(oHtml:ValByName("it1.UFF")			, TRBD4->A2_EST		) //Estado do Fornecedor
				aadd(oHtml:ValByName("it1.RisF")		, TRBD4->A2_RISCO	) //Risco do Fornecedor
				aadd(oHtml:ValByName("it1.CodForF")		, TRBD4->A5_CODPRF	) //Codigo no Forncedor
				TRBD4->(dbSkip())
			End
		Else //Caso nao tenha dados      6 if
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
		EndIf                                // 6 if
		TRBD4->(dbCloseArea())
	Else                                            // 5 if
		//Query busca Fornecedores do Grupo de Produtos
		cQuery4 := " SELECT AD_FORNECE, AD_LOJA, A2_NOME, A2_TEL, A2_CONTATO, A2_FAX, A2_ULTCOM, A2_MUN, A2_EST, A2_RISCO"
		cQuery4 += " FROM "+RetSqlName('SB1')+" B1"
		cQuery4 += " INNER JOIN "+RetSqlName('SAD')+" AD ON B1_GRUPO = AD_GRUPO"
		cQuery4 += " INNER JOIN "+RetSqlName('SA2')+" A2 ON AD_FORNECE = A2_COD AND AD_LOJA = A2_LOJA"
		cQuery4 += " WHERE B1_COD = '"+TRBD->C1_PRODUTO+"'"
		cQuery4 += " AND AD.D_E_L_E_T_ <> '*'"
		cQuery4 += " AND A2.D_E_L_E_T_ <> '*'"
		cQuery4 += " AND B1.D_E_L_E_T_ <> '*'"
		cQuery4 += " ORDER BY  A2_ULTCOM DESC"
		dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQuery4),"TRBD4", .F., .T.)
		TcSetField("TRBD4","A2_ULTCOM","D")
		If !TRBD4->(EOF())                                      // 7 if
			dbSelectArea("TRBD4")
			TRBD4->(dbGoTop())
			nContador := 0
			While !TRBD4->(EOF())
				nContador++
				If nContador > 03 //Numero de Fornecedores
					Exit
				EndIf
				aadd(oHtml:ValByName("it1.CodF")		, TRBD4->AD_FORNECE	) //Codigo do Fornecedor
				aadd(oHtml:ValByName("it1.LjF")			, TRBD4->AD_LOJA		) //Codigo da Loja
				aadd(oHtml:ValByName("it1.NomeF")		, TRBD4->A2_NOME		) //Nome do Fornecedor
				aadd(oHtml:ValByName("it1.TelF")		, TRBD4->A2_TEL		) //Telefone do Fornecedor
				aadd(oHtml:ValByName("it1.ContF")		, TRBD4->A2_CONTATO	) //Contato no Fornecedor
				aadd(oHtml:ValByName("it1.FaxF")		, TRBD4->A2_FAX		) //Fax no Fornecedor
				aadd(oHtml:ValByName("it1.UlComF")		, DTOC(TRBD4->A2_ULTCOM)	) //Ultima Compra com o Fornecedor
				aadd(oHtml:ValByName("it1.MunicF")		, TRBD4->A2_MUN		) //Municipio do Fornecedor
				aadd(oHtml:ValByName("it1.UFF")			, TRBD4->A2_EST		) //Estado do Fornecedor
				aadd(oHtml:ValByName("it1.RisF")		, TRBD4->A2_RISCO	) //Risco do Fornecedor
				aadd(oHtml:ValByName("it1.CodForF")		, ""				) //Codigo no Forncedor
				TRBD4->(dbSkip())
			End
		Else //Caso nao tenha dados                   7 if
		/*
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
			*/
		EndIf          // 7 if
		TRBD4->(dbCloseArea())
	endif // 5 if
	//envia o e-mail
	oProcess:ClientName( Subs(cUsuario,7,15) )
	oProcess:cTo := cMailAp
	oProcess:cSubject := "Aprovação Pedido de Compra "+ cnum
	//	oProcess:bReturn := "u_MT120WF( 1 )"
	oProcess:cBody    	:= ""
	//		oProcess:bTimeOut := {{"U_WFW120T(2)", 0 ,0 ,2 }}
	TRBD->(dbCloseArea())
	oProcess:Start()
	//RastreiaWF( ID do Processo, Codigo do Processo, Codigo do Status, Descricao Especifica, Usuario )
	RastreiaWF("PEDCOM"+'.'+oProcess:fTaskID,"PEDCOM",'100005',"Pedido de Compras "+cNum+" Enviado para o Aprovador")
	oProcess:Free()
	oProcess:= Nil                                                                       
	PutMv("MV_WFHTML",cMvAtt)
	//WFSendMail({cEmpant,cFilant})
Return()

Static Function MT120WFr(oProcess)
	Local lLast := .T.,_oProc,nTotal
	Local lLibPed:=	.F.           
	RastreiaWF(oProcess:fProcessID+'.'+oProcess:fTaskID,oProcess:fProcCode,'100002','Respondendo ao email',"BI")
	DbSelectArea('SC7')
	Dbsetorder(1)
	dbSeek(xFilial('SC7')+oProcess:oHtml:RetByName('Pedido'))
	If Found()
		ConOut('Processando pedido de compra: '+SC7->C7_NUM)
		If oProcess:oHtml:RetByName("Aprovacao") = "S"
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
					cQuery+=		"WHERE  CR_NUM = '" + SC7->C7_NUM + "' AND CR_FILIAL = '"+XFILIAL("SC7")+ "' AND CR_STATUS = '03' AND SCR.D_E_L_E_T_ = ' ' "
					dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQuery),"TRBL", .F., .T.)
					nTotLib:=	TRBL->TOT
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
					SCR->CR_Obs     := oProcess:oHtml:RetByName('LbMotivo')
					If oProcess:oHtml:RetByName('cAprov') == SCR->CR_USER
						SCR->CR_STATUS  := "03"
					Else
						If nTotLib >= 1
							SCR->CR_STATUS  := "05"					
						Endif
					Endif
					MsUnLock()
					DbSelectarea("SCR")
					DbSkip()
				End
				If lLibPed
					MT120WFf(oProcess) // Manda email para fornecedor
				Endif
			Else                    
				Private _cNomeRep:=	""
				If PedJaRep()
					//Envio WF avisando que o pedido ja foi REPROVADO
					PswOrder(1)
					If PswSeek(oProcess:oHtml:RetByName('cAprov'),.t.)
						aInfo   := PswRet(1)
						_cMailTo 	:= alltrim(aInfo[1,14])
					Endif
					// Declaracao das variaveis para envio do email.
					Private cMailBox := AllTrim(WFGetMV( "MV_WFMLBOX", "" ))
					Private cTo      := _cMailTo
					Private oMail    := TWFMail():New()
					Private oMailBox := oMail:GetMailBox( cMailBox )
					Private cHtml    := ""
					Private cSubject := "Pedido já Reprovado anteriormente"
					Private cBody    := "O PEDIDO "+SC7->C7_NUM+" JA FOI REPROVADO PELO APROVADOR "+UPPER(Alltrim(_cNomeRep))+"."
					Private aAttachs := {}
					oMailBox:NewMessage( cTo,,, cSubject, cBody, aAttachs )
					oMailBox:Send() //Enviando email
					
				EndIf
				
				If SC7->C7_CONAPRO == "L"
					//Executa a Liberacao com Codigo 03 do Aprovador.
					DBSelectarea("SCR")
					DbSetorder(2)
					DbSeek(xFilial("SCR")+"PC"+SC7->C7_NUM+Space(44)+oProcess:oHtml:RetByName('cAprov'))
					If Found()
						RecLock("SCR",.f.)
						SCR->CR_DataLib := dDataBase
						SCR->CR_Obs     := oProcess:oHtml:RetByName('LbMotivo')
						SCR->CR_STATUS  := "03"
						MsUnLock()
					Endif
				
				EndIf
				
			EndIf
		Else // Caso reprovado
			If SC7->C7_CONAPRO == "L"
				//Enviar e-mail para o proprio aprovador
				Private _cNomeApr:=	""
				If PedJaApr()
					PswOrder(1)
					If PswSeek(oProcess:oHtml:RetByName('cAprov'),.t.)
						aInfo   := PswRet(1)
						_cMailTo 	:= alltrim(aInfo[1,14])
					Endif
					//Envio WF avisando que o pedido ja foi APROVADO
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
				DbSeek(xFilial("SCR")+"PC"+SC7->C7_NUM+Space(44)+oProcess:oHtml:RetByName('cAprov'))
				If Found()
					RecLock("SCR",.f.)
					SCR->CR_DataLib := dDataBase
					SCR->CR_STATUS  := "04" //Bloqueio    
					SCR->CR_OBS		:= oProcess:oHtml:RetByName('LbMotivo')
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
					//Pego e-mail do Solicitante responsável pelo Pedido
					DbSelectArea("SC1")
					DbSetOrder(1)
					DbSeek(xfilial("SC1")+SC7->C7_NUMSC)
					PswOrder(1)
					If PswSeek(SC1->C1_USER,.t.)
						aInfo   	:= PswRet(1)
						_cMailTo 	+= "; "+alltrim(aInfo[1,14])
					Endif
					PswOrder(1)
					If PswSeek(oProcess:oHtml:RetByName('cAprov'),.t.)
						aInfo   	:= PswRet(1)
						_cNomeRep 	:= alltrim(aInfo[1,2])
					Endif
					//Envio WF avisando que o Pedido foi Reprovado
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
         			//Como ultima acao, Muda Status
					dbselectarea("SC7")
					DBSETORDER(1)
					DBSeek(xFilial("SC7")+SC7->C7_NUM)      // Posiciona o Pedido
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
	EndIf
Return()

/*
BEGINDOC
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Funcao para checar se o Pedido já esta REPROVADO³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
ENDDOC
*/
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
Return(lRet)

/*
BEGINDOC
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Funcao para checar se o Pedido já esta APROVADO³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
ENDDOC
*/
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
Return(lRet)

Static Function MT120WFt(oProcess)
	If oProcess == NIL
		oProcess := TWFProcess():New( "PEDCOM", "Pedido de Compras" )
	Endif
ConOut("Funcao de TIMEOUT executada")
oProcess:NewTask('Time Out',"\workflow\htm\timeout.htm")
oHtml:=oProcess:oHtml
oHtml:RetByName("Titulo","Usuario não respondeu e-mail")
oHtml:RetByName("numPed",_cPedido)
oHtml:RetByName("cliente",_ccliente)
_cUser = Subs(cUsuario,7,15)
oHtml:RetByName("usuario",_cUser)
subj := "Pedido"+ _cPedido + " por " + _ccliente
oProcess:Start()
//WFSendMail()
Return()

Static Function MT120WFf(oProcess)
	If oProcess == NIL
		oProcess := TWFProcess():New( "PEDCOM", "Pedido de Compras" )
	Endif
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
_oProc:NewTask( "Solicitação de Pedido", "\workflow\htm\mt120wf2.htm" )
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
oHtml:ValByName( "PEDIDO", SC7->C7_NUM )
cNum := SC7->C7_NUM
dbSetOrder(1)
dbSeek(xFilial('SC7')+cNum)
nTotal := 0
While !Eof() .and. C7_NUM = cNum
	nTotal := nTotal + C7_TOTAL
	AAdd( (oHtml:ValByName( "it.item" )),C7_ITEM )
	AAdd( (oHtml:ValByName( "it.codigo" )),C7_PRODUTO )
	dbSelectArea('SB1')
	dbSetOrder(1)
	dbSeek(xFilial('SB1')+SC7->C7_PRODUTO)
	dbSelectArea('SC7')
	AAdd( (oHtml:ValByName( "it.descricao" )),SB1->B1_DESC )
	AAdd( (oHtml:ValByName( "it.quant" )),TRANSFORM( C7_QUANT,'@E 999,999.99' ) )
	AAdd( (oHtml:ValByName( "it.preco" )),TRANSFORM( C7_PRECO,'@E 999,999.99' ) )
	AAdd( (oHtml:ValByName( "it.total" )),TRANSFORM( C7_TOTAL,'@E 999,999.99' ) )
	AAdd( (oHtml:ValByName( "it.unid" )),SB1->B1_UM )
	dbSkip()
Enddo
oHtml:ValByName( "lbValor" ,TRANSFORM( nTotal,'@E 999,999.99' ) )
oHtml:ValByName( "lbFrete" ,TRANSFORM( 0,'@E 999,999.99' ) )
oHtml:ValByName( "lbTotal" ,TRANSFORM( nTotal,'@E 999,999.99' ) )
dbSelectArea('SC7')
dbSetOrder(1)
dbSeek(xFilial('SC7')+cNum)
SA2->(dbSetOrder(1))
ConOut(xFilial("SA2")+SC7->C7_FORNECE+SC7->C7_LOJA)
SA2->(dbSeek(xFilial("SA2")+SC7->C7_FORNECE+SC7->C7_LOJA))
_oProc:cTo := SA2->A2_EMAIL
ConOut("Email:"+SA2->A2_EMAIL)
_oProc:Start()
RastreiaWF("PEDCOM"+'.'+_oProc:fTaskID,"PEDCOM",'100007',"Pedido de Compras "+cNum+" Aprovado. Enviado para o Fornecedor")
_oProc:Finish()
Return()