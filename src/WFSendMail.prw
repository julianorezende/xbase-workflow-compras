#Include 'Protheus.ch'

User Function WFSendMail()
	Local oMail, oMailBox
	Conout("Enviando emails...")
	oMail := TWFMail():New({"01", "01010001"})
	oMailBox := oMail:GetMailBox("WORKFLOW")
	oMailBox:Send(, "")  
Return

