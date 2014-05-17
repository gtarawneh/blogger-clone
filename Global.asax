<%@ Application Language="C#" %>

<%@ Import Namespace ="System.IO" %>

<%@ Import Namespace ="System.Data.OleDb" %>

<%@ Import Namespace = "System.Net.Mail" %>

<script runat="server">

    void Application_Start(object sender, EventArgs e) 
    {
        // Code that runs on application startup

        OleDbConnection Con = new OleDbConnection();

        Con.ConnectionString = "Provider=Microsoft.Jet.OLEDB.4.0;data source=" + Server.MapPath("~/Data/MyData.mdb");

        Con.Open();

        Application["Con"] = Con;

        ReloadApplicationSettings();

        ReloadApplicationData();

    }

    private void ReloadApplicationData()
    {

        StreamReader S = File.OpenText(Server.MapPath ("~/Data/template.htm"));

        Application ["Template"] = S.ReadToEnd();

        S.Close();

        S = File.OpenText(Server.MapPath("~/Data/email_template.htm"));

        Application["EmailTemplate"] = S.ReadToEnd();

        S.Close();

        S = File.OpenText(Server.MapPath("~/Data/user_message.htm"));

        Application["UserMessage"] = S.ReadToEnd();

        S.Close();

        PrepareErrorMessages();
               
        Application["PostsFeed"] = GeneratePostsFeed();
        
        ReloadRT();

        Application ["Blocked"] = new ArrayList(); 

        if (Server.MachineName == "Z60")
        {
            Application ["RootPath"] = "http://localhost:1075/blog/";
            
            Application["IsRemote"] = false;
        }
        else
        {
            Application["RootPath"] = "http://localhost/blog/";

            Application["IsRemote"] = true;
        }
    }

    private void ReloadApplicationSettings()
    {
        OleDbConnection Con = (OleDbConnection)Application["Con"];

        OleDbCommand Com = new OleDbCommand("select * from Settings order by ID", Con);

        OleDbDataReader R = Com.ExecuteReader();
        
        int i = 1;
        

        while (R.Read())
        {
            Application["Setting" + i.ToString()] = R["Content"];
            
            i++;
        }

        R.Close();
            

    }

    private void PrepareErrorMessages()
    {
        string NotFound = (string)Application["UserMessage"];

        NotFound = NotFound.Replace("%TITLE%", "404 File Not Found");

        NotFound = NotFound.Replace("%WIDTH%", "500");

        string msg = "The file or directory you requested does not exist on this server.<br/><br/>" +

            "Please check the link you provided and try again.";

        NotFound = NotFound.Replace("%MESSAGE%", msg);

        Application["Err404Message"] = NotFound;
 
        string GeneralErr = (string)Application["UserMessage"];

        GeneralErr = GeneralErr.Replace("%TITLE%", "Server Error");

        GeneralErr = GeneralErr.Replace("%WIDTH%", "550");

        msg = "An unexpected error occured while processing your request. " +

                         "The website administrator has been notified and will deal with " +

                         "the problem shortly.<br /><br />We're sorry for the inconvenience.";

        GeneralErr = GeneralErr.Replace("%MESSAGE%", msg);

        Application["ErrMessage"] = GeneralErr;

    }
    
    public void ReloadRT()
    {
        // Reloads Redirection Table

        Hashtable RT = new Hashtable(); // Initialize Redirection table

        OleDbCommand Com = new OleDbCommand();

        Com.Connection = (OleDbConnection ) Application ["Con"];

        Com.CommandText = "select * from Posts where PostDraft=0";

        OleDbDataReader R = Com.ExecuteReader();

        while (R.Read())
        {
            RT.Add((string)R["PostVirtualFile"], Convert.ToString(R["PostID"]));
        }

        R.Close();

        Application["RT"] = RT;
    }
    
    void Application_End(object sender, EventArgs e) 
    {
        //  Code that runs on application shutdown

        OleDbConnection Con = (OleDbConnection)Application["Con"];

        Con.Close();
        

    }
 
    void Application_Error(object sender, EventArgs e) 
    { 
        // Code that runs when an unhandled error occurs

        if ((bool) Application["IsRemote"] == false) return; // Alows debugging information to be viewed locally
        
        Exception objErr = Server.GetLastError().GetBaseException();

        if (objErr.Message.Contains("does not exist"))
        {
            Response.Write((string) Application ["Err404Message"]);

            Response.End();
            
            return;
            
        }
        else
        {

            Response.Write((string)Application["ErrMessage"]);

            Response.End();

            Server.ClearError();

            if ((string)Application["Setting12"] == "1") // If Error Reporting = On
            {
                string err = "Error Caught in Application_Error event<br/><br/>" +

                "<b>Error URL: </b>" + Request.Url.ToString() + "<br/><br/>" +
                
                "<b>Error Line: </b>" + objErr.ToString () + "<br/><br/>" +

                "<b>Error Message: </b>" + objErr.Message.ToString()+ "<br/><br/>" +
                
                "<b>Error Trace: </b><br/><br/>" + objErr.StackTrace.Replace ("\r\n","<br/>");

                string blog_email = "no-reply@localhost";

                string recepient_email = (string) Application ["Setting13"];

                string subject = "["+ (string) Application ["Setting2"]+"] Application Error Report";

                string body = err;

                string sender_info = "\"" + "Error Reporter" + "\" <" + blog_email + ">";

                string recepient_info = recepient_email;

                MailMessage message = new MailMessage(sender_info, recepient_info, subject, body);

                SmtpClient emailClient = new SmtpClient((string) Application ["Setting20"] );

                System.Net.NetworkCredential SMTPUserInfo = new System.Net.NetworkCredential("admin@localhost", "noblockip");

                emailClient.UseDefaultCredentials = false;

                emailClient.Credentials = SMTPUserInfo;

                message.IsBodyHtml = true;

                if ((bool)Application["IsRemote"]) emailClient.Send(message);
            }
        }
    }

    void Session_Start(object sender, EventArgs e) 
    {

        // Visitor Tracking

        if (Request.Browser.Cookies && Session["Tracked"] == null)
        {
            Session["Tracked"] = "Yes";

            OleDbCommand Com = new OleDbCommand();

            Com.Connection = (OleDbConnection)Application["Con"];

            string browser_name = Request.Browser.Browser;

            string browser_version = Request.Browser.Version;

            string platform = Request.Browser.Platform;

            string last_url = Request.Url.ToString();

            DateTime last_visit = DateTime.Now;

            if ((bool)(Application["IsRemote"]) == true) last_visit = last_visit.AddHours(Convert.ToDouble(Application["Setting19"]));

            string IP = Request.UserHostAddress;

            if (IP != "")
            {
                

                Com.CommandText = "select count(*) as C from Visitors where IP='" + IP + "'";
                
                int c = -1;

                try
                {
                    c = (int)Com.ExecuteScalar();
                }
                catch (Exception)
                {
                    Response.Write("#");
                    Response.Write(IP);
                    Response.Write("#");
                }
                    
                if (c == 1)
                {
                    // Visitor identified by IP Address

                    Com.CommandText = "select ID from visitors where IP='" + Request.UserHostAddress + "'";

                    string cookie_id = Com.ExecuteScalar().ToString();

                    Response.Cookies["VisitorID"].Value = cookie_id;

                    Response.Cookies["VisitorID"].Expires = DateTime.Now.AddYears(99);

                    Com.CommandText = "update visitors set visits=visits+1, browsername='" + browser_name +

                                      "', browserversion='" + browser_version + "', platform='" + platform +

                                      "', lastvisit='" + last_visit.ToString() + "', lasturl='" + last_url +

                                      "' where IP='" + Request.UserHostAddress + "'";

                    Com.ExecuteNonQuery();

                }
                
                if (c == 0)
                {
                    bool cookie_id_found = Request.Cookies["VisitorID"] != null;

                    string cookie_id = "None";

                    try
                    {
                        cookie_id = Request.Cookies["VisitorID"].Value;
                    }
                    catch (Exception)
                    {
                    }

                    Com.CommandText = "select count(*) from visitors where ID='" + cookie_id + "'";

                    bool cookie_id_exists = (Com.ExecuteScalar().ToString() == "1");

                    if (cookie_id_found && cookie_id_exists)
                    {

                        // Visitor identified by Cookie ID

                        Com.CommandText = "update visitors set visits=visits+1, browsername='" + browser_name +

                                      "', browserversion='" + browser_version + "', platform='" + platform +

                                      "', lastvisit='" + last_visit.ToString() + "', IP='" + Request.UserHostAddress +

                                      "', lasturl='" + last_url + "' where ID='" +

                                      cookie_id + "'";

                        Com.ExecuteNonQuery();
                    }
                    else
                    {
                        // New Visitor

                        Random R = new Random();

                        cookie_id = "";

                        for (int i = 0; i < 16; i++) cookie_id += (char)R.Next(97, 122);

                        Response.Cookies["VisitorID"].Value = cookie_id;

                        Response.Cookies["VisitorID"].Expires = DateTime.Now.AddYears(99);

                        Com.CommandText = "insert into visitors (ID, Visits, BrowserName, BrowserVersion, Platform, LastVisit, IP, LastURL, CmtName)" +

                                          " values ('" + cookie_id + "', 1, '" + browser_name + "', '" +

                                          browser_version + "', '" + platform + "', '" + last_visit.ToString() +

                                          "', '" + Request.UserHostAddress + "', '" + last_url + "','')";

                        Com.ExecuteNonQuery();

                    }
                }
            }
        }
        
        

    }

    void Session_End(object sender, EventArgs e) 
    {
        // Code that runs when a session ends. 
        // Note: The Session_End event is raised only when the sessionstate mode
        // is set to InProc in the Web.config file. If session mode is set to StateServer 
        // or SQLServer, the event is not raised.

    }

    public string GeneratePostsFeed()
    {
        
        string feed = "";

        string root_path = (string)Application["RootPath"];

        feed += "<?xml version='1.0' encoding='UTF-8'?>";
        
        feed += "<?xml-stylesheet href=\"http://www.blogger.com/styles/atom.css\" type=\"text/css\"?>";

        feed += "<feed xmlns='http://www.w3.org/2005/Atom' xmlns:openSearch='http://a9.com/-/spec/opensearchrss/1.0/'>";

        feed += "<link rel='http://schemas.google.com/g/2005#feed' type='application/atom+xml' href='http://localhost/Blog/feeds/posts'/>";

        // feed += "<updated>2007-09-12T01:55:09.957+03:00</updated>";
        
        feed += "<updated>" + DateTime.Now.ToUniversalTime ().ToString ("yyyy-MM-ddThh:mm:ss.000+00:00") + "</updated>";

        feed += "<title type='text'>" +  (string) Application ["Setting2"] +"</title>";
        
        feed += "<link rel='alternate' type='text/html' href='" + root_path  + "'/>";

        feed += "<link rel='self' type='application/atom+xml' href='" + root_path + "feeds/posts'/>";

        feed += "<author><name>Owner</name></author>";

        feed += "<generator>Owner</generator>";

        OleDbConnection Con = (OleDbConnection) Application["Con"];

        OleDbCommand Com = new OleDbCommand("select top " +  Application ["Setting14"].ToString () +" * from posts where PostBlogPage=0 and PostDraft=0 order by postdate desc;", Con);

        OleDbDataReader R = Com.ExecuteReader();
        
        while (R.Read ())
        {
            feed += "<entry>";

            feed += "<id>" + Convert.ToString ((int) R["PostId"]) + "</id>";
       
            //feed += "<published>" + ((DateTime) R["PostDate"]).ToString () + "</published>";
            
            feed += "<published>" + ((DateTime) R["PostDate"]).ToUniversalTime ().ToString ("yyyy-MM-ddThh:mm:ss.000+00:00") + "</published>";

            //feed += "<updated>" + ((DateTime) R["PostDate"]).ToString () + "</updated>";
            
            feed += "<updated>" + ((DateTime) R["PostDate"]).ToUniversalTime ().ToString ("yyyy-MM-ddThh:mm:ss.000+00:00") + "</updated>";
            
            //DateTime.Now.ToUniversalTime().ToString ("yyyy-MM-ddThh:mm:ss.000+00:00")

            feed += "<title type='text'>" + EscapeContent ((string) R["PostTitle"]) + "</title>";
        
            feed += "<content type='html'>" +EscapeContent ( (string) R["PostBody"]) + "</content>";
         
            feed += "<link rel='alternate' type='text/html' href='" + root_path +EscapeContent ( (string) R["PostVirtualFile"]) + "' title='" + EscapeContent ((string) R["PostTitle"] )+  "'/>";
                       
            feed += "<author><name>Owner</name></author>";
         
            feed += "</entry>";
        }
        
        feed += "</feed>";

        return feed;
    }

    public string EscapeContent(string s)
    {
        
        s = s.Replace("&", "&amp;");

        s = s.Replace("<", "&lt;");

        s = s.Replace(">", "&gt;");

        s = s.Replace("'", "&apos;");

        s = s.Replace("\"", "&quot;");

        return s;
    }
        

    protected void Application_BeginRequest(object sender, EventArgs e)
    {
       
        if ((string)Application["SettingsReloaded"] == null)
        {
            ReloadApplicationSettings();

            Application["SettingsReloaded"] = "Done";
        }
        
        if ((string ) Application["DataReloaded"] == null)
        {
            ReloadApplicationData();
            
            Application["DataReloaded"] = "Done";
        }



        string requested_path = Request.FilePath.ToLower();
        
        // Fix for GoDaddy

        string x = Request.Url.ToString();
        
        if (x.Contains ("?404;"))
        {
            string y = x.Substring(x.IndexOf("?404;") + 5);

            requested_path = y.ToLower();

            requested_path = requested_path.Substring(7);

            requested_path = requested_path.Substring(requested_path.IndexOf("/"));
        }
        
        // End of Fix
        
        int i = requested_path.LastIndexOf("/");
        
        string requested_file = requested_path.Substring(i + 1);

        Hashtable RT = (Hashtable)Application["RT"];

        string post_id = (string)RT[requested_file];

        if (post_id != null)
        {
            // A matching post virtual file is found

            string redirect_to = "default.aspx?id=" + post_id;

            Server.Transfer(redirect_to);
        }

        if (requested_path.Contains("archive/"))
        {

            if (requested_path.Contains(".htm"))
            {

                int j = requested_path.IndexOf("archive/");

                string param = requested_path.Substring(j + 8);

                param = param.Remove(param.Length - 4, 4);

                string root_path = (string)Application["RootPath"];

                Server.Transfer(  "~/default.aspx?id=" + param);
            }
            else
            {
                int j = 0;

                string file_name = requested_path;

                for (int k = 1; k < 5; k++)
                {
                    j = file_name.IndexOf("/");

                    file_name = file_name.Substring(j + 1);
                }

                if (file_name.Contains(".htm"))
                {
                    Server.Transfer("~/" + file_name);
                }
                else
                {
                    Response.Redirect("~/" + file_name);
                }

            }

        }

        if (requested_path=="/blog/feeds/posts")
        {
            Response.ContentType = "text/xml";

            Response.Write((string) Application["PostsFeed"]);

            Response.End();
        }
      
    }

</script>
