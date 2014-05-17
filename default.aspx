<%@ Page Language="C#" ValidateRequest ="false"  EnableSessionState ="true"  %>

<%@ Import Namespace="System.Data.OleDb" %>

<%@ Import Namespace = "System.Net.Mail" %>

<script runat="server">
    
    string PostID = "";

    string Archive = "";
    
    bool ItemPage = false;

    bool PreviewPage = false;

    bool ArchivePage = false;

    bool CommentPosted = false;

    OleDbConnection Con;

    OleDbCommand Com;

    OleDbDataReader R;
    
    protected void Page_Load()
    {
        // Reading template.htm contents

        string template = (string)Application["Template"];
        
        string param = (string) Request.Params["id"];

        string preview = (string)Request.Params["field3"];

        if (param == null)
        {
            if (preview == null)
            {
                // Main Page
            }
            else
            {
                PreviewPage = true;

                ItemPage = true;
            }
        }
        else if (param.Contains("/"))
        {
            // Archive Page

            Archive = param;
            
            ArchivePage = true ;
        }
        else 
        {
            // Item Page

            PostID = param;

            ItemPage = true;
        }
        
        // Preparing data access objects

        Con = (OleDbConnection)Application["Con"];

        Com = new OleDbCommand();

        Com.Connection = Con;

        // Checking for a comment post

        CommentPosted = (Request.Form["cmtPostID"] != null && Request.Form["CommentBox"] != "" && Request.Form["CommentBox"] != null);

        if (CommentPosted)
        {
            if ((string)Application["Setting7"] == "1") // If Comment Flood Protection = On
            {
                string hours_difference = "0";

                if ((bool)(Application["IsRemote"]) == true) hours_difference = (string) Application["Setting19"];

                string  protection_time_span = (string)Application["Setting8"];

                int max_comments = Convert.ToInt32 ( Application["Setting9"]);

                string cmt_ip = Request.UserHostAddress;

                string sql2 = "SELECT Count(*) AS C FROM Comments WHERE (((DateDiff('n',[ComDate],DateAdd('h'," + hours_difference + ",Now())))<" +  protection_time_span  +")) and ComIP='" + cmt_ip +"';";
                
                Com.CommandText = sql2;
                
                int comments = (int) Com.ExecuteScalar();

                if (comments >= max_comments)
                {
                    // Deny posting comment
                    
                    string DenyComment = (string)Application["UserMessage"];

                    DenyComment = DenyComment.Replace("%TITLE%", "Comment Flood Protection");

                    DenyComment = DenyComment.Replace("%WIDTH%", "500");

                    string msg = "You have posted too many comments recently. The blog will not accept any further comments from you right now, please try again later.";

                    DenyComment = DenyComment.Replace("%MESSAGE%", msg);

                    Response.Write(DenyComment);

                    Response.End();

                    return;
                }
                
                
                           
            }
            
            string cmt_post_id = Request.Form["cmtPostID"];

            string cmt_name = Request.Form["nameBox"];

            string cmt_email = Request.Form["emailBox"];

            string cmt_url = Request.Form["urlBox"];

            string cmt_body = Request.Form["CommentBox"];

            if (cmt_name == null || cmt_name == "") cmt_name = "Anonymous";

            if (cmt_email == null) cmt_email = "";

            if (cmt_url == null) cmt_url = "";

            cmt_body = ProcessComment(cmt_body);

            cmt_body = cmt_body.Replace("'", "' + chr(39) + '");
            
            //cmt_name = cmt_name.Replace("'", "' + chr(39) + '");

            ArrayList Blocked = (ArrayList) Application["Blocked"];

            bool isAnnoyer = CheckIsAnnoyer(cmt_name, cmt_body);

            bool isListed = Blocked.Contains(Request.UserHostAddress);

            string temp = cmt_body.ToLower();
            
            int link_count = 0;

            while (temp.Contains("http:"))
            {
                int pos = temp.IndexOf("http:");

                temp = temp.Insert(pos+1, "x");

                link_count++;
            }

            string sql3 = "SELECT max(PostID) as M FROM Posts;";
            
            Com.CommandText = sql3;
            
            int newestPostID = (int) Com.ExecuteScalar ();
            
            string sql4 = "select count(*) as C from comments where composter='" + cmt_name.Replace("'", "' + chr(39) + '") + "' and composter<>'anonymous' and comvisible=true";
            
            Com.CommandText = sql4;
            
            int previous_comments_with_same_name = (int) Com.ExecuteScalar();
            
            bool isSpam = CheckFilters(cmt_name) || CheckFilters(cmt_url) || CheckFilters(cmt_body) || (link_count > 3);
            
            bool BlockCookieExists = (Request.Cookies ["LoginInfo"] != null);

            bool isCookieBlocked = BlockCookieExists ? (Request.Cookies["LoginInfo"].Value  == "Saved") : false ;
            
            bool known_blogservice_url = cmt_url.ToLower().Contains("blosgspot") || cmt_url.ToLower().Contains("wordpress") || (cmt_url == "");

            bool isAd = cmt_body.ToLower().Contains("buy") || cmt_body.ToLower().Contains("http") || !known_blogservice_url;

            bool isBlocked = isListed || isSpam || isCookieBlocked;

            bool willModerate = isAd || isAnnoyer;

            if (cmt_post_id != newestPostID.ToString () && previous_comments_with_same_name==0) willModerate = true;

            if (isBlocked)
            {
                // Comment is spam!

                string DenyComment = (string)Application["UserMessage"];

                DenyComment = DenyComment.Replace("%TITLE%", "Comment Spam Protection");

                DenyComment = DenyComment.Replace("%WIDTH%", "450");

                string msg = "The comment you posted was rejected because it contains spam."

                + " If you think this happened by mistake, please contact the blog owner.";

                DenyComment = DenyComment.Replace("%MESSAGE%", msg);

                Response.Write(DenyComment);

                Response.Cookies["LoginInfo"].Expires = DateTime.Now.AddDays(7);

                Response.Cookies["LoginInfo"].Value = "Saved";

                if (!isListed) Blocked.Add(Request.UserHostAddress);

                Response.End();

                return;
            }

            string ComVisible = "1";

            if (willModerate) ComVisible = "0";

            DateTime dt = DateTime.Now;

            if ((bool) (Application ["IsRemote"]) == true) dt = dt.AddHours(Convert.ToDouble (  Application ["Setting19"]) );

            string cmt_date = dt.ToString("dd/MMM/yyyy hh:mm:ss tt");

            string sql = "insert into comments (ComPostID, ComPoster, ComPosterLink,ComBody,ComIP, ComDate, ComEmail, ComVisible)";

            sql += " values ('" + cmt_post_id + "', '" + cmt_name.Replace("'", "' + chr(39) + '") + "', '"
                
                + cmt_url.Replace("'", "' + chr(39) + '") +"', '" + cmt_body + "', '" + Request.UserHostAddress
                
                + "','" + cmt_date + "','" + cmt_email.Replace("'", "' + chr(39) + '") +"'," +ComVisible + ");";

            Com.CommandText = sql;

            Com.ExecuteNonQuery();

            sql = "update Visitors set CmtName='" + cmt_name.Replace("'", "' + chr(39) + '") 
                
                + "' where IP='" + Request.UserHostAddress + "'";

            Com.CommandText = sql;

            Com.ExecuteNonQuery();

            sql = "select * from Posts where PostID=" + PostID;

            Com.CommandText = sql;

            OleDbDataReader R = Com.ExecuteReader();

            while (R.Read())
            {
                string title = (string)R["PostTitle"];

                string link = (string)Application["RootPath"] + (string)R["PostVirtualFile"];

                string cmt_date2 = dt.ToString("MMMM d, yyyy h:mm tt");

                cmt_body = cmt_body.Replace( "' + chr(39) + '","'");

                if ((string)Application["Setting3"] == "1") // If Email Notifications = On
                {
                    if ((string)Application["Setting10"] == "0") // If Disable Comment Notifications for Specific Users = Off
                    {
                        SendEmailNotification(cmt_name, cmt_body, title, link, cmt_date2);

                        if ((string)Application["Setting5"] == "1") // If Enable SMS Comment Notifications = On
                        {
                            SendSMSNotification(cmt_name, cmt_body, title, link, cmt_date2);
                        }
                        
                    }
                    else
                    {
                        string specific_users = (string)Application["Setting11"];

                        int l = specific_users.Split(';').Length ;

                        bool send_mail = true;

                        for (int i = 0; i < l; i++)
                        {
                            if (cmt_name.ToLower() == specific_users.Split(';')[i].ToLower())
                            {
                                send_mail = false;
                            }
                        }

                        if (send_mail && !willModerate)
                        {
                            SendEmailNotification(cmt_name, cmt_body, title, link, cmt_date2);
                            
                            if ((string)Application["Setting5"] == "1") // If Enable SMS Comment Notifications = On
                            {
                                SendSMSNotification(cmt_name, cmt_body, title, link, cmt_date2);
                            }
                        }
                        
                        
                    }
                        
                }
            }

            R.Close();

            if (willModerate)
            {
                AwaitModeration();

                return;
            }
                
        }
        
                
        // Document processing

        template = CapitalizeAllBloggerTags(template);
        
        template = RemoveTags (template ,"<ITEMPAGE>","</ITEMPAGE>", !ItemPage);

        template = RemoveTags (template,"<MAINORARCHIVEPAGE>","</MAINORARCHIVEPAGE>", ItemPage);
              
        string blogger_code = GetCode(template, "<BLOGGER>", "</BLOGGER>");

        if (PreviewPage)
        {
            template = ReplaceCode(template,"<BLOGGER>","</BLOGGER>", ProcessPreviewPost(blogger_code));
        }
        else
        {
            try
            {
                template = ReplaceCode(template, "<BLOGGER>", "</BLOGGER>", ProcessPosts(blogger_code));
            }
            catch (Exception)
            {
                Display404();

                return;
            }
        }

        if (ItemPage)
        {
            // Processing Comments

            if (PreviewPage)
            {
                template = RemoveTags (template,"<BLOGITEMCOMMENTSENABLED>","</BLOGITEMCOMMENTSENABLED>", true);
            }
            else
            {
                string comment_code = GetCode (template ,"<BLOGITEMCOMMENTS>","</BLOGITEMCOMMENTS>");
                template = ReplaceCode (template,"<BLOGITEMCOMMENTS>","</BLOGITEMCOMMENTS>", ProcessComments(comment_code));
            }
            
        }
        
        // Process Previous Items List

        string previous_code = GetCode(template, "<BLOGGERPREVIOUSITEMS>", "</BLOGGERPREVIOUSITEMS>");

        template = ReplaceCode (template,"<BLOGGERPREVIOUSITEMS>","</BLOGGERPREVIOUSITEMS>", ProcessPreviousItems(previous_code));
        
        try
        {
            template = ProcessGeneralTags(template); 
        }
        catch (Exception)
        {
            Display404();

            return;
        }
 
        // Process Archives List

        string archives_code = GetCode (template ,"<BLOGGERARCHIVES>","</BLOGGERARCHIVES>");

        template = ReplaceCode (template,"<BLOGGERARCHIVES>","</BLOGGERARCHIVES>", ProcessArchives(archives_code));

        

        // Sending document to client

        Response.Write(template);

        Response.End();

    }

    private void Display404()
    {
        string NotFound = (string)Application["UserMessage"];

        NotFound = NotFound.Replace("%TITLE%", "404 File Not Found");

        NotFound = NotFound.Replace("%WIDTH%", "500");

        string msg = "The file or directory you requested does not exist on this server.<br/><br/>" +

            "Please check the link you provided and try again.";

        NotFound = NotFound.Replace("%MESSAGE%", msg);

        Response.Write(NotFound);

        Response.End();
    }

    private void AwaitModeration()
    {
        string temp = (string)Application["UserMessage"];

        temp = temp.Replace("%TITLE%", "Awaiting Moderation");

        temp = temp.Replace("%WIDTH%", "500");

        string msg = "Your comment has been suspected for containing spam/objectionable material. It will not"

            + " be displayed until the blog owner approves it.<br><br>"
            
            + "<a href='!!'>Click here</a> to return to the post page.";

        msg = msg.Replace("!!", Request.Url.AbsoluteUri);

        temp = temp.Replace("%MESSAGE%", msg);

        Response.Write(temp);

        Response.End();
    }

    public string ProcessGeneralTags(string TemplateCode)
    {
        // This function will process the general tags

        TemplateCode = TemplateCode.Replace("<$BLOGURL$>", (string) Application ["RootPath"]);

        string Title = (string) Application ["Setting2"];

        string blog_meta_data = "";

        blog_meta_data += "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\" />\r\n";

        blog_meta_data += "<meta name=\"generator\" content=\"User\" />\r\n";

        blog_meta_data += "<link rel=\"alternate\" type=\"application/atom+xml\" title=\"" + Title +" - Atom\" href=\"" + (string ) Application ["RootPath"] +"feeds/posts\" />\r\n";

        TemplateCode = TemplateCode.Replace("<$BLOGMETADATA$>", blog_meta_data);

        if (ItemPage && !PreviewPage )
        {
            Com.CommandText = "select * from Posts where PostID=" + PostID;

            R = Com.ExecuteReader();

            R.Read();

            Title += " &raquo; " + (string)R["PostTitle"];

            TemplateCode = TemplateCode.Replace("<$BLOGITEMNUMBER$>", PostID);

            TemplateCode = TemplateCode.Replace("<$BLOGITEMPERMALINKURL$>", Request.ApplicationPath.ToLower () + "/" + (string)R["PostVirtualFile"]);

            R.Close();
            
        }

        if (PreviewPage)
        {
            Title += " &raquo; " + (string)Request["field1"];

            TemplateCode = TemplateCode.Replace("<$BLOGITEMPERMALINKURL$>", "default.aspx");
        }

        if (ArchivePage)
        {
            Com.CommandText = "select * from ArchivePostCount where arch2='" + Archive  + "'";

            R = Com.ExecuteReader();

            R.Read();

            Title += " &raquo; " + (string)R["arch"] + " Archive";

            R.Close();

        }
        
        TemplateCode = TemplateCode.Replace("<$BLOGPAGETITLE$>", Title);

        return TemplateCode;
    }

    public string ProcessPreviewPost(string BloggerCode)
    {

        // This function will process the posts tags for post previewing

        string result = "";
 
        string Post_Code = BloggerCode;

        Post_Code = Post_Code.Replace("<$BLOGITEMTITLE$>", (string) Request["field1"] );

        Post_Code = Post_Code.Replace("<$BLOGITEMBODY$>", (string)Request["field2"]);

        Post_Code = Post_Code.Replace("<$BLOGDATEHEADERDATE$>", DateTime.Now.ToLongDateString());

        Post_Code = Post_Code.Replace("<$BLOGITEMCOMMENTCOUNT$>", "0");

        Post_Code = Post_Code.Replace("<$BLOGITEMPERMALINKURL$>", (string) Application ["RootPath"] + "default.aspx" );

        result += Post_Code;

        return result;
    }

    public string ProcessPosts(string BloggerCode)
    {
        
        // This function will process the posts tags
        
        string result = "";

        Com.CommandText = "select ComPostID, count(ComPostID) as C from Comments where ComVisible=true group by ComPostID";
  
        R = Com.ExecuteReader();

        Hashtable H = new Hashtable();
        
        while (R.Read())
        {
            H.Add (Convert.ToString ( R[0]) , Convert.ToString (R[1]));
        }

        R.Close();

        if (ItemPage)
        {
            Com.CommandText = "select * from Posts where PostID=" + PostID;
        }
        else if (ArchivePage)
        {
            Com.CommandText = "SELECT * FROM Posts WHERE (((Format([Posts]![PostDate],'yyyy/mmmm',1,1))='" + Archive + "')) and PostBlogPage=0 and PostDraft=0  order by (PostDate) desc;";

        }
        else
        {
            // Main Page

            Com.CommandText = "select top 4 * from Posts where PostBlogPage=0 and PostDraft=0 order by (PostDate) desc;";
        }

        R = Com.ExecuteReader();

        bool records_exist = false;

        while (R.Read())
        {
            records_exist = true;

            string Post_Code = BloggerCode;

            Post_Code = Post_Code.Replace("<$BLOGITEMTITLE$>", (string)R["PostTitle"]);

            Post_Code = Post_Code.Replace("<$BLOGITEMBODY$>", (string)R["PostBody"]);

            Post_Code = Post_Code.Replace("<$BLOGDATEHEADERDATE$>", ((DateTime)R["PostDate"]).ToLongDateString());

            string CommentsCount = (string)H[Convert.ToString(R["PostID"])];

            if (CommentsCount == null) CommentsCount = "0";

            Post_Code = Post_Code.Replace("<$BLOGITEMCOMMENTCOUNT$>", CommentsCount);

            Post_Code = Post_Code.Replace("<$BLOGITEMPERMALINKURL$>", Request.ApplicationPath.ToLower() + "/" + (string)R["PostVirtualFile"]);

            Post_Code = RemoveTags(Post_Code,"<BLOGITEMCOMMENTSENABLED>","</BLOGITEMCOMMENTSENABLED>", !((bool) R["PostAllowComments"]));

            result += Post_Code;
        }
        
        
        
        R.Close();
        
        if (!records_exist ) throw new Exception (); 

        return result;
        
        
    }

    public string ProcessComments(string CommentCode)
    {
        string result = "";

        Com.CommandText = "select count(*) as c from Comments where ComVisible=true and ComPostID=" + PostID;

        int count = (int)Com.ExecuteScalar();

        Com.CommandText = "select * from Comments where ComVisible=true and ComPostID=" + PostID + " order by ComDate;";

        R = Com.ExecuteReader();

        int i = 0;

        while (R.Read())
        {
            
            string single_comment = CommentCode;

            string author = (string)R["ComPoster"];

            string link = Convert .ToString ( R["ComPosterLink"]);
            
            if (link.Length >7) if (link.ToLower().Substring(0, 7) != "http://") link = "http://" + link;

            if (link != "") author = "<a href='" + link + "' rel=\"nofollow\" target='_blank'>" + author + "</a>";

            single_comment = single_comment.Replace("<$BLOGCOMMENTAUTHOR$>", author);

            DateTime DT = (DateTime) R["ComDate"];

            string Comment_DT = DT.ToString("MMM dd, yyyy h:mm tt");

            single_comment = single_comment.Replace("<$BLOGCOMMENTDATETIME$>", Comment_DT);

            single_comment = single_comment.Replace("<$BLOGCOMMENTBODY$>", (string) R["ComBody"]);

            i++;

            single_comment = RemoveTags (single_comment,"<BLOGCOMMENTNEWEST>","</BLOGCOMMENTNEWEST>", i != count);

            result += single_comment;
            
        }

        R.Close();

        return result;
    }

    public string ProcessPreviousItems(string PreviousCode)
    {
        string result = "";

        int count = 10;

        if (PreviewPage) count--;

        if (ItemPage && !PreviewPage )
        {
            Com.CommandText = "select top " + count.ToString() + " * from Posts where PostDate<(select PostDate from Posts where PostID=" + PostID + ") and  PostBlogPage=0 and PostDraft=0 order by (PostDate) desc;";
        }
        else
        {
            Com.CommandText = "select top " + count.ToString() + " * from Posts where PostBlogPage=0 and PostDraft=0 order by PostDate desc;";
        }
        
        R = Com.ExecuteReader();

        bool PreviewPageFlag = PreviewPage;

        while (R.Read())
        {
            string PreviousItemCode = PreviousCode;

            if (PreviewPageFlag)
            {
                string PreviousItemCode1 = PreviousCode;
                
                PreviousItemCode1 = PreviousItemCode1.Replace("<$BLOGPREVIOUSITEMTITLE$>", (string) Request["field1"] );

                PreviousItemCode1 = PreviousItemCode1.Replace("<$BLOGITEMPERMALINKURL$>", "default.aspx");

                result += PreviousItemCode1;

                PreviewPageFlag = false;
            }
                

            PreviousItemCode = PreviousItemCode.Replace("<$BLOGPREVIOUSITEMTITLE$>", (string)R["PostTitle"]);

            PreviousItemCode = PreviousItemCode.Replace("<$BLOGITEMPERMALINKURL$>", Request.ApplicationPath.ToLower () + "/" + (string) R["PostVirtualFile"] );

            result += PreviousItemCode;
          
        }

        R.Close();

        return result;
        
    }

    public string ProcessArchives(string ArchivesCode)
    {
        string result = "";

        if (ArchivePage)
        {
            Com.CommandText = "select top 10 * from ArchivePostCount where FirstOfPostDate < (select FirstOfPostDate from ArchivePostCount where arch2='" + Archive   + "') order by FirstOfPostDate desc;";
        }
        else
        {
            Com.CommandText = "select top 10 * from ArchivePostCount;";
        }

        R = Com.ExecuteReader();

        while (R.Read())
        {
            string ArchivesItemCode = ArchivesCode;

            ArchivesItemCode = ArchivesItemCode.Replace("<$BLOGARCHIVEURL$>", Request.ApplicationPath.ToLower ()  +"/archive/" + ((string)R["arch2"]).ToLower () + ".htm");

            ArchivesItemCode = ArchivesItemCode.Replace("<$BLOGARCHIVENAME$>", (string)R["arch"] + " (" + Convert.ToString((int)R["postcount"]) + ")");

            result += ArchivesItemCode;

        }

        R.Close();

        return result;

    }
    public string CapitalizeAllBloggerTags(string template)
    {
        template = CapitalizeBloggerTag(template, "<itempage>");

        template = CapitalizeBloggerTag(template, "</itempage>");

        template = CapitalizeBloggerTag(template, "<blogger>");

        template = CapitalizeBloggerTag(template, "</blogger>");

        template = CapitalizeBloggerTag(template, "<$BlogItemTitle$>");

        template = CapitalizeBloggerTag(template, "<$BlogItemBody$>");

        template = CapitalizeBloggerTag(template, "<$BlogDateHeaderDate$>");

        template = CapitalizeBloggerTag(template, "<$BlogItemCommentCount$>");

        template = CapitalizeBloggerTag(template, "<$BlogItemPermalinkURL$>");

        template = CapitalizeBloggerTag(template, "<MainOrArchivePage>");

        template = CapitalizeBloggerTag(template, "</MainOrArchivePage>");

        template = CapitalizeBloggerTag(template, "<$BlogURL$>");

        template = CapitalizeBloggerTag(template, "<$BlogPageTitle$>");

        template = CapitalizeBloggerTag(template, "<BlogItemComments>");

        template = CapitalizeBloggerTag(template, "</BlogItemComments>");

        template = CapitalizeBloggerTag(template, "<$BlogCommentAuthor$>");
        
        template = CapitalizeBloggerTag(template, "<$BlogCommentDateTime$>");

        template = CapitalizeBloggerTag(template, "<$BlogCommentBody$>");
        
        template = CapitalizeBloggerTag(template, "<BloggerPreviousItems>");

        template = CapitalizeBloggerTag(template, "</BloggerPreviousItems>");

        template = CapitalizeBloggerTag(template, "<$BlogPreviousItemTitle$>");

        template = CapitalizeBloggerTag(template, "<BloggerArchives>");

        template = CapitalizeBloggerTag(template, "<$BlogArchiveURL$>");

        template = CapitalizeBloggerTag(template, "<$BlogArchiveName$>");

        template = CapitalizeBloggerTag(template, "</BloggerArchives>");
        
        template = CapitalizeBloggerTag(template, "<$BlogItemNumber$>");
        
        template = CapitalizeBloggerTag(template, "<BlogCommentNewest>");
        
        template = CapitalizeBloggerTag(template, "</BlogCommentNewest>");

        template = CapitalizeBloggerTag(template, "<$BlogMetaData$>");

        template = CapitalizeBloggerTag(template, "<BlogItemCommentsEnabled>");

        template = CapitalizeBloggerTag(template, "</BlogItemCommentsEnabled>");
        
        return template;
    }
        
        
        

    public string CapitalizeBloggerTag(string template, string tag)
    {
        
        // Turns all occurances of a certain tag to uppercase

        string temp = template.ToUpper();

        int i;

        while ((i=temp.IndexOf (tag.ToUpper ()))!= -1)
        {


            temp = temp.Remove(i, 1 );
            temp = temp.Insert(i, "X");

            template = template.Remove(i, tag.Length );
            template = template.Insert(i, tag.ToUpper() );
        }
        

        return template;
    }

    public string ReplaceCode(string template, string start_tag, string end_tag, string code)
    {
        // Replaces two given tags and their contents with processed code

        int start = template.IndexOf(start_tag);

        if (start == -1) return template;

        int l = GetCode(template, start_tag, end_tag).Length + start_tag.Length + end_tag.Length;

        template = template.Remove(start, l);

        template = template.Insert(start, code);

        return template;
    }

    public string GetCode(string template, string start_tag, string end_tag)
    {
        // Returns a string containing the code between two specified tags

        int start = template.IndexOf(start_tag);

        int end = template.IndexOf(end_tag);

        if (start == -1 || end == -1) return template;

        return template.Substring(start + start_tag.Length, end - start - start_tag.Length);

    }

    public string RemoveTags(string code, string start_tag, string end_tag, bool RemoveContents)
    {
        // Removes two tags, and optionally their contents

        int i, j;

        while ((i = code.IndexOf(start_tag)) != -1)
        {
            j = code.IndexOf(end_tag);

            if (RemoveContents)
            {
                code = code.Remove(i, j - i + end_tag.Length);
            }
            else
            {
                code = code.Remove(i, start_tag.Length);
                code = code.Remove(j - start_tag.Length, end_tag.Length);
            }
        }
        return code;
    }
    
   
    private bool ValidateTag(string contents)
    {
        string l = contents.ToLower();

        if (l == "b") return true;
        if (l == "br/") return true;

        if (l == "u") return true;
        if (l == "i") return true;
        if (l == "/b") return true;
        if (l == "/u") return true;
        if (l == "/i") return true;
        if (l == "/a") return true;

        if (l.Contains("href"))
        {
            if (l.Length > 7)
                if (l.Substring(0, 7) == "a href=")
                {
                    if (l.IndexOf(' ', 3) == -1) return true;
                }
        }

        return false;
    }

    private string FixTags(string s)
    {

        char last = '>';

        char current = '<';

        for (int i = 0; i < s.Length; i++)
        {
            current = s[i];

            if (current == '<')
            {
                if (last == '<') s = s.Remove(i--, 1);

                last = '<';
            }

            if (current == '>')
            {
                if (last == '>') s = s.Remove(i--, 1);

                last = '>';
            }
        }

        if (last == '<') s += ">";

        return s;
    }

    public string ProcessComment(string x)
    {
        x = FixTags(x);

        if (x.Length >1) while (x.Substring(x.Length - 2) == "\r\n") x = x.Substring(0, x.Length - 2);

        x = x.Replace("\r\n", "<br/>");

        int l = x.Length;

        for (int i = 0; i < x.Length; i++)
        {
            char c = x[i];

            if (c == '<')
            {
                int j = x.IndexOf('>', i);

                string contents = x.Substring(i + 1, j - i - 1);

                if (!ValidateTag(contents))
                {
                    // remove tag
                    x = x.Remove(i, j - i + 1);

                    i--;
                }
            }

        }

        return x;
    }

    protected void SendEmailNotification(string commentator_name, string comment_body, string post_title, string post_link, string comment_date)
    {
        string blog_email = "no-reply@localhost";

        string recepient_email = (string) Application ["Setting4"];

        string subject = "["+(string) Application ["Setting2"]+"] New comment on " + post_title;

        string body = (string)Application["EmailTemplate"];

        body = body.Replace("%NAME%", commentator_name);

        body = body.Replace("%BODY%", comment_body);

        body = body.Replace("%POSTLINK%", post_link);

        body = body.Replace("%POSTTITLE%", post_title);

        body = body.Replace("%COMMENTDATE%", comment_date);

        string recepient_info = recepient_email;

        string sender_info = "\"" + commentator_name  + "\" <" + blog_email  + ">";

        MailMessage message = new MailMessage(sender_info, recepient_info, subject, body);

        SmtpClient emailClient = new SmtpClient((string) Application ["Setting20"] );

        System.Net.NetworkCredential SMTPUserInfo = new System.Net.NetworkCredential("admin@localhost", "noblockip");

        emailClient.UseDefaultCredentials = false;

        emailClient.Credentials = SMTPUserInfo;

        message.IsBodyHtml = true;

        if ((bool)Application["IsRemote"]) emailClient.Send(message);

    }

    protected void SendSMSNotification(string commentator_name, string comment_body, string post_title, string post_link, string comment_date)
    {
        string blog_email = "no-reply@localhost";

        string recepient_email = (string)Application["Setting6"];

        string subject = "[" + (string)Application["Setting2"] + "] New comment on " + post_title;

        string body = "(" + commentator_name +  ") has just posted a new comment on \"" + post_title + "\".";

        string recepient_info = recepient_email;

        string sender_info = "\"" + commentator_name + "\" <" + blog_email + ">";

        MailMessage message = new MailMessage(sender_info, recepient_info, subject, body);

        SmtpClient emailClient = new SmtpClient((string)Application["Setting20"]);

        System.Net.NetworkCredential SMTPUserInfo = new System.Net.NetworkCredential("admin@localhost", "noblockip");

        emailClient.UseDefaultCredentials = false;

        emailClient.Credentials = SMTPUserInfo;

        message.IsBodyHtml = true;

        if ((bool)Application["IsRemote"]) emailClient.Send(message);

    }

    private bool CheckFilters(string x)
    {
        // Returns true if a string applies to any spam filter(s)
        
        x = "x" + x + "x";
        
        string sql  = "select count(*) as C from Filters where FilterType=1 and FilterAction=1 and '" + x + "' like FilterContent;";

        OleDbCommand C = new OleDbCommand(sql, (OleDbConnection)Application["Con"]);

        int c = (int)C.ExecuteScalar();
        
        return (c==0) ? false : true;
    }

    private bool CheckIsAnnoyer(string nam, string body)
    {
        // Returns true if the comment is submitted by an annoyer

        nam = ClearText (nam.ToLower());

        body = ClearText(body.ToLower());

        if (nam.Contains("j") && nam.Contains("o") && nam.Contains("n") && nam.Contains("d")) return true;

        if (body.Contains ("fuckyou") || body.Contains ("fucku")||  body.Contains("sex") || body.Contains("gay") || body.Contains("hooker")) return true;

        if (nam.Contains("sex") || nam.Contains("gay") || nam.Contains("fuck")) return true;

        return false;
    }

    private string ClearText(string text)
    {
        // This function strips a string from non-alpha-numeric characters
        
        for (int i = 0; i < text.Length; i++)
        {
            char c = text[i];

            if ((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9'))
            {
                // it's Ok =)
            }
            else
            {
                text = text.Remove(i, 1);
                i--;
            }
        }
        return text;
    }


    /*
    public string GetBloggerCode(string template)
    {
        // Returns a string containing the code between the <blogger> and </blogger> tags

        int blogger_start = template.IndexOf("<BLOGGER>");

        int blogger_end = template.IndexOf("</BLOGGER>");

        return template.Substring(blogger_start + 9, blogger_end - blogger_start - 9);
        
    }
*/

    /*
    public string ReplaceBloggerCode(string template, string code)
    {
        // Replaces the <blogger>, </blogger> tags and their contents with processed code
        
        int blogger_start = template.IndexOf("<BLOGGER>");

        int l = GetCode (template ,"<BLOGGER>","</BLOGGER>").Length + 19;

        template = template.Remove(blogger_start, l);

        template = template.Insert(blogger_start, code);

        return template;
    }
     * */
    /*
        public string GetCommentCode(string template)
        {
            // Returns a string containing the code between the <BlogItemComments> and </BlogItemComments> tags

            int blogger_start = template.IndexOf("<BLOGITEMCOMMENTS>");

            int blogger_end = template.IndexOf("</BLOGITEMCOMMENTS>");

            if (blogger_start == -1) return "";

            return template.Substring(blogger_start + 18, blogger_end - blogger_start - 18);

        }
    */
    /*
    public string ReplaceCommentCode(string template, string code)
    {
        // Replaces the <BlogItemComments>, </BlogItemComments> tags and their contents with processed code

        int comment_start = template.IndexOf("<BLOGITEMCOMMENTS>");

        if (comment_start == -1) return template;

        int l =GetCode (template ,"<BLOGITEMCOMMENTS>","</BLOGITEMCOMMENTS>").Length + 37;

        template = template.Remove(comment_start, l);

        template = template.Insert(comment_start, code);

        return template;
    }
     * */
    /*
        public string GetPreviousItemsCode(string template)
        {
            // Returns a string containing the code between the <BloggerPreviousItems> and </BloggerPreviousItems> tags

            int blogger_start = template.IndexOf("<BLOGGERPREVIOUSITEMS>");

            int blogger_end = template.IndexOf("</BLOGGERPREVIOUSITEMS>");

            return template.Substring(blogger_start + 22, blogger_end - blogger_start - 22);

        }
    */
    /*
    public string ReplacePreviousCode(string template, string code)
    {
        // Replaces the <BloggerPreviousItems>, </BloggerPreviousItems> tags and their contents with processed code

        int previous_start = template.IndexOf("<BLOGGERPREVIOUSITEMS>");

        int l = GetCode(template,"<BLOGGERPREVIOUSITEMS>","</BLOGGERPREVIOUSITEMS>").Length + 45;

        template = template.Remove(previous_start, l);

        template = template.Insert(previous_start, code);

        return template;
    }
*/

    /*

    public string GetArchivesCode(string template)
    {
        // Returns a string containing the code between the <BloggerArchives> and </BloggerArchives> tags

        int Archives_start = template.IndexOf("<BLOGGERARCHIVES>");

        int Archives_end = template.IndexOf("</BLOGGERARCHIVES>");

        return template.Substring(Archives_start + 17, Archives_end - Archives_start - 17);

    }
*/
    /*
    public string ReplaceArchivesCode(string template, string code)
    {
        // Replaces the <BloggerArchives>, </BloggerArchives> tags and their contents with processed code

        int archives_start = template.IndexOf("<BLOGGERARCHIVES>");

        int l = GetCode (template ,"<BLOGGERARCHIVES>","</BLOGGERARCHIVES>").Length + 35;

        template = template.Remove(archives_start, l);

        template = template.Insert(archives_start, code);

        return template;
    }
    */


    /*
    public string RemoveItemPageTags(string code, bool RemoveContents)
    {
        // Remove the <ItemPage> and </ItemPage> tags' contents, and optionally their contents
        
        int i, j;

        while ((i = code.IndexOf("<ITEMPAGE>")) != -1)
        {
            j = code.IndexOf("</ITEMPAGE>");

            if (RemoveContents)
            {
                code = code.Remove(i, j - i + 11);
            }
            else
            {
                code = code.Remove(i, 10);
                code = code.Remove(j - 10, 11);
            }
        }
        return code;
    }
     */
    /*
        public string RemoveNewestCommentTags(string code, bool RemoveContents)
        {
            // Remove the <BlogCommentNewest> and </BlogCommentNewest> tags' contents, and optionally their contents

            int i, j;

            while ((i = code.IndexOf("<BLOGCOMMENTNEWEST>")) != -1)
            {
                j = code.IndexOf("</BLOGCOMMENTNEWEST>");

                if (RemoveContents)
                {
                    code = code.Remove(i, j - i + 21);
                }
                else
                {
                    code = code.Remove(j, 20);
                    code = code.Remove(i, 19);
                
                }
            }
            return code;
        }
    */
    /*
    public string RemoveCommentsSectionTags(string code, bool RemoveContents)
    {
       int i, j;

        while ((i = code.IndexOf("<BLOGITEMCOMMENTSENABLED>")) != -1)
        {
            j = code.IndexOf("</BLOGITEMCOMMENTSENABLED>");

            if (RemoveContents)
            {
                code = code.Remove(i, j - i + 27);
            }
            else
            {
                code = code.Remove(j, 26);
                code = code.Remove(i, 25);
                
            }
        }
        return code;
    }
     * */

    /*
        public string RemoveMainOrArchivePageTags(string code, bool RemoveContents)
        {
            // Remove the <MainOrArchivePage> and </MainOrArchivePage> tags' contents, and optionally their contents
        
            int i, j;

            while ((i = code.IndexOf("<MAINORARCHIVEPAGE>")) != -1)
            {
                j = code.IndexOf("</MAINORARCHIVEPAGE>");

                if (RemoveContents)
                {
                    code = code.Remove(i, j - i + 20);
                }
                else
                {
                    code = code.Remove(i, 19);
                    code = code.Remove(j - 19, 20);
                }
            }
            return code;
        }
    
    */

</script>

<html xmlns ="http://www.w3.org/1999/xhtml" >
<head>
<title >
</title>
</head>
<body >
</body>
</html>



