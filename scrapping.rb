require 'rubygems'
require 'nokogiri' 
require 'open-uri'
# require 'pry'

# Load the google_drive gem
require 'google_drive'

# Load the gmail gem
require 'gmail'

#Load the dotenv gem
require 'dotenv'

# This tells dotenv to read the .env file and set the appropriate values in ENV
Dotenv.load

# méthode pour récupérer l'adresse email à partir d'une page web de mairie
def gets_the_email_of_townhall_from_its_webpage(url)
	page = Nokogiri::HTML(open(url))
	emails = page.css("tr td.style27 p.Style22 font") # array emails regroupant les éléments dont le chemin a été précisé
	emails.each do |i| # itération sur l'array pour obtenir l'élément i
		if i.text.include?"@" # si le texte de l'élément i contient @
			return i.text[1...i.text.length] # on affiche le texte de l'élément i sans le premier caractère (espace effacé)
		end
	end
end

# méthode pour récupérer les url et ranger dans un Hash les paires Ville / emails
def get_all_the_urls_of_department_townhalls(dep)
		town_hash = Hash.new # création du Hash town_hash
		dep_url = "http://annuaire-des-mairies.com/"+dep+".html" # on définit une variable qui renvoie à l'adresse url du département
		page = Nokogiri::HTML(open(dep_url))
		urls = page.css("a.lientxt") # on définit une variable urls qui renvoie à un array des a de classe lientxt
		urls.each do |url| # itération sur l'array pour obtenir l'élément url
			clean_url = "http://annuaire-des-mairies.com"+url['href'][1...url['href'].length] # clean url est un string concaténé de http://...et de l'attribut href de l'élément url sans son premier caractère
			town_hash[url.text.capitalize] = gets_the_email_of_townhall_from_its_webpage(clean_url) # classement dans le hash
		end
		return town_hash
end

# méthode pour enregistrer le Hash dans un Google Spreadsheet
def get_element_of_hash_to_spreadsheet(dep)
	town_hash = get_all_the_urls_of_department_townhalls(dep) # on définit une variable qui encapsule le hash avec les urls
	session = GoogleDrive::Session.from_config("config.json") # on définit une variable égale à une nouvelle session Google Drive
	ws = session.spreadsheet_by_key("17OAMGgiBJ5AbHN3lfzY4BPxAQIPteR4o1mk2uI5Mxd4").worksheets[0] # variable égale à la feuille 1 dans le classeur
# au itère au sein du hash town_hash pour enregistrer les clés et les valeurs du hash dans les colonnes A & B du Google Spreadsheet
	i = 1
	town_hash.each do |key,value|
		ws[i,1] = key # ville
		ws[i,2] = value # email
		i+=1
		end
	ws.save # il faut appeler ws.save pour que les modifications soient envoyées au serveur
end
# get_element_of_hash_to_spreadsheet("haute-corse")

# méthode pour envoyer un email à ligne n du spreadsheet
def send_email_to_line(address,town,client_email)
email = client_email.compose do
  to address
  subject "Apprendre à coder avec THP"
  html_part do
               content_type 'text/html; charset=UTF-8'
              body "<p>Bonjour,</p> 
               <p>Je m'appelle Bob, je suis élève à une <strong>formation de code gratuite, ouverte à tous, sans restriction géographique, ni restriction de niveau.</strong> La formation s'appelle The Hacking Project (http://thehackingproject.org). Nous apprenons l'informatique via la méthode du peer-learning : nous faisons des projets concrets qui nous sont assignés tous les jours, sur lesquel nous planchons en petites équipes autonomes. Le projet du jour est d'envoyer des emails à nos élus locaux pour qu'ils nous aident à faire de The Hacking Project un nouveau format d'éducation gratuite.</p>
               <p>Nous vous contactons pour vous parler du projet, et vous dire que vous pouvez ouvrir une cellule à #{town}, où <strong>vous pouvez former gratuitement 6 personnes (ou plus), qu'elles soient débutantes, ou confirmées.</strong> Le modèle d'éducation de The Hacking Project n'a pas de limite en terme de nombre de moussaillons (c'est comme cela que l'on appelle les élèves), donc nous serions ravis de travailler avec #{town}.</p>
            <p>Charles, co-fondateur de The Hacking Project pourra répondre à toutes vos questions : 06.95.46.60.80</p>
            <p>Amicalement,</p>
            <p>Bob from THP</p>"
          end
end
email.deliver! # or: gmail.deliver(email)
client_email.logout
end

def go_through_all_the_lines
# connexion à la session Google Drive
session = GoogleDrive::Session.from_config("config.json")
ws = session.spreadsheet_by_key("17OAMGgiBJ5AbHN3lfzY4BPxAQIPteR4o1mk2uI5Mxd4").worksheets[0]
# connexion au compte Gmail grâce au Dotenv
username = ENV['GMAIL_USERNAME']
password = ENV['GMAIL_PASSWORD']
gmail = Gmail.connect(username, password)
# play with your gmail...
# p gmail.inbox.count # display number of emails in inbox
# p ws[n,2] # afficher la valeur contenue colonne B ligne n du spreadsheet google drive
# p ws.num_rows # display number of rows of data
	ws.rows.each do |row|
		send_email_to_line(row[1],row[0],gmail) unless row[1]=="0"
	end
end
go_through_all_the_lines


