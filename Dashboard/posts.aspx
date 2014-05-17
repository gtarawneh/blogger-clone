<%@ Page Language="C#" MasterPageFile="~/Dashboard/MasterPage.master" Title="Blog Posts" %>

<%@ Import Namespace="System.Data.OleDb" %>

<script type="text/C#" runat="server">

    protected void Page_Load()
    {
        Session["Section"] = "Blog Posts";

        Session["Section-Title"] = "Blog Posts";

        // Creating and initializing data acess objects

        OleDbConnection Con = (OleDbConnection)Application["Con"];

        OleDbCommand Com = new OleDbCommand();

        Com.CommandText = "select count(*) as C from posts";

        Com.Connection = Con;

        OleDbDataReader R;

        // Processing page

        int PostCount = (int)Com.ExecuteScalar();

        int Posts_Per_Page = 10;

        int Pages = (int)Math.Ceiling((double)PostCount / Posts_Per_Page);

        int Selected_Page = Convert.ToInt32(Request["page"]);

        if (Selected_Page == 0) Selected_Page = 1;

        Session["CancelPage"] = Request.Url.ToString () ;

        Label2.Text = "( Page " + Convert.ToString(Selected_Page) + " of " + Convert.ToString(Pages) + ")";

        if (Selected_Page < Pages)
        {
            // Enabling Next Page link

            HyperLink2.Visible = true;
            HyperLink2.NavigateUrl = "posts.aspx?page=" + Convert.ToString(Selected_Page + 1);
        }
        else
        {
            HyperLink2.Visible = false;
        }

        if (Selected_Page != 1)
        {
            // Enabling Previous Page link

            HyperLink1.Visible = true;
            HyperLink1.NavigateUrl = "posts.aspx?page=" + Convert.ToString(Selected_Page - 1);
        }
        else
        {
            HyperLink1.Visible = false;
        }

        int Skipped_Posts = (Selected_Page - 1) * Posts_Per_Page;

        if (Skipped_Posts > 0)
        {

            Com.CommandText = "SELECT TOP " + Convert.ToString(Posts_Per_Page) + " PostID, PostTitle,PostDate,PostVirtualFile,PostDraft, PostBlogpage, count(ComID) as c FROM Posts left join Comments ON Posts.PostID = Comments.ComPostID GROUP BY PostID,PostTitle,PostDate,PostVirtualFile, PostDraft, PostBlogPage having (((Posts.PostID) Not In (select top " + Convert.ToString(Skipped_Posts) + " PostID from Posts order by PostDraft, PostDate desc)));";
        }
        else
        {
            Com.CommandText = "SELECT TOP " + Convert.ToString(Posts_Per_Page) + " PostID, PostTitle,PostDate,PostVirtualFile,PostDraft, PostBlogPage,count(ComID) as c FROM Posts left join Comments ON Posts.PostID = Comments.ComPostID GROUP BY PostID,PostTitle,PostDate,PostVirtualFile,PostDraft, PostBlogPage order by PostDraft, PostDate desc;";
        }

        R = Com.ExecuteReader();

        Rep1.DataSource = R;

        Rep1.DataBind();

        R.Close();

    }

    private string GetCommentHTML(object Container)
    {
        int count =(int) DataBinder.Eval(Container, "c");

        if (count == 0)
        {
            return "<i><span style='color:rgb(175,175,175);'>(None)</span></i>";
        }
        else
        {

            string s = (count == 1) ? "" : "s";
        
            return DataBinder.Eval (Container ,"c").ToString ()+ " Comment" + s + " (<a href=\"comments.aspx?id=" +  DataBinder.Eval (Container,"PostID").ToString () +"\">Moderate</a>)";
        }


    }

    private string GeneratePostLabel(object Container)
    {
        if ((bool)DataBinder.Eval(Container, "PostDraft")) return "<i>(Draft)</i>";
        
        if ((bool)DataBinder.Eval(Container, "PostBlogPage")) return "<i>(Blog Page)</i>";
        
        return "";
    }

    private string GenerateViewLinkVisibility(object Container)
    {
        if ((bool)DataBinder.Eval(Container, "PostDraft")) return "hidden"; else return "visible";
    }

</script>

<asp:Content runat="server" ContentPlaceHolderID="ContentPlaceHolder1">
    <asp:Repeater ID="Rep1" runat="server">
        <HeaderTemplate>
            <table id="PostsTable">
                <tr id="HeaderRow">
                    <td class="TitleCell" style="width: 350px;">
                        Post Title</td>
                    <td style="width: 50px;">
                        <center>
                            Edit</center>
                    </td>
                    <td style="width: 80px;">
                        <center>
                            View</center>
                    </td>
                    <td style="width: 10px;">
                    </td>
                    <td style="width: 220px;"><center >
                        Comments</center></td>
                    <td style ="width:100px;">
                        <center>
                            Posting Date</center>
                    </td>
                    <td style="width: 100px;">
                        <center>
                            Delete</center>
                    </td>
                </tr>
        </HeaderTemplate>
        <ItemTemplate>
            <tr>
                <td class="TitleCell">
                    <span class="PostTitle">
                        <%#DataBinder.Eval(Container.DataItem, "PostTitle")%>
                        <%# GeneratePostLabel(Container.DataItem) %>
                    </span>
                </td>
                <td>
                    <center>
                        <a href="editpost.aspx?id=<%#DataBinder.Eval(Container.DataItem, "PostID")%>"><span
                            class="EditLink">Edit</span></a></center>
                </td>
                <td>
                    <center>
                        <a target="_blank" href="../<%#DataBinder.Eval(Container.DataItem, "PostVirtualFile")%>">
                            <span style="visibility:<%# GenerateViewLinkVisibility(Container.DataItem) %>" class="ViewLink">View</span></a></center>
                </td>
                <td>
                </td>
                <td><center >
                    
                    <%# GetCommentHTML(Container.DataItem) %>
                </center></td>
                <td>
                    <center>
                        <%# ((DateTime ) DataBinder.Eval(Container.DataItem, "PostDate")).ToString ("dd MMM yyyy") %>
                    </center>
                </td>
                <td>
                    <center>
                        <a href="deletepost.aspx?id=<%#DataBinder.Eval(Container.DataItem, "PostID")%>"><span
                            class="DeleteLink">Delete</span></a>
                    </center>
                </td>
            </tr>
        </ItemTemplate>
        <AlternatingItemTemplate>
            <tr class="OddRow">
                <td class="TitleCell">
                    <span class="PostTitle">
                        <%#DataBinder.Eval(Container.DataItem, "PostTitle")%>
                        <%# GeneratePostLabel(Container.DataItem) %>
                    </span>
                </td>
                <td>
                    <center>
                        <a href="editpost.aspx?id=<%#DataBinder.Eval(Container.DataItem, "PostID")%>"><span
                            class="EditLink">Edit</span></a></center>
                </td>
                <td>
                    <center>
                        <a target="_blank" href="../<%#DataBinder.Eval(Container.DataItem, "PostVirtualFile")%>">
                            <span style="visibility:<%# GenerateViewLinkVisibility(Container.DataItem) %>" class="ViewLink">View</span></a></center>
                </td>
                </center>
                <td>
                </td>
                <td><center > <%# GetCommentHTML(Container.DataItem) %></center> </td>
                <td>
                    <center>
                        <%# ((DateTime ) DataBinder.Eval(Container.DataItem, "PostDate")).ToString ("dd MMM yyyy") %>
                    </center>
                </td>
                <td>
                    <center>
                        <a href="deletepost.aspx?id=<%#DataBinder.Eval(Container.DataItem, "PostID")%>"><span
                            class="DeleteLink">Delete</span></a>
                    </center>
                </td>
            </tr>
        </AlternatingItemTemplate>
        <FooterTemplate>
            </table>
        </FooterTemplate>
    </asp:Repeater>
    <br />
    <table style="width: 900px; font-size: 11px;">
        <tr>
            <td style="text-align: left; width: 33%">
                <asp:HyperLink ID="HyperLink1" runat="server"><span class ="PreviousPage">Previous Page</span></asp:HyperLink>
            </td>
            <td style="text-align: center">
                <asp:Label ID="Label2" runat="server" Text="(Page 1 of 8)"></asp:Label>
            </td>
            <td style="text-align: right; width: 33%">
                <asp:HyperLink ID="HyperLink2" runat="server" NavigateUrl=""><span class ="NextPage">Next Page</span></asp:HyperLink>
            </td>
        </tr>
    </table>
</asp:Content>
