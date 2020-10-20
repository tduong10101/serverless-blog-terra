![](https://github.com/tduong10101/serverless-blog-terra/blob/master/HighlevelDesign.jpg)

I'm learning Terraform at the moment. I think this is a good hand-on side project for me. The provided terraform code will spin up a github repo, a codebuild project and a s3 bucket to host a static blog (blue box in the flow chart above). I figure people might not want to use cloudfront or route 53, so I left them out. 

Also just a side note, Terraform doesn't help with register domain on Route 53. While AWS does offer the ability to register domain names, this is not something we would want Terraform to manage as we can't simply "unregister" a domain name.

To spin this up, we will need the below prerequisites:
- [Github personal access token](https://docs.github.com/en/free-pro-team@latest/github/authenticating-to-github/creating-a-personal-access-token)
- [AWS CLI](https://aws.amazon.com/cli/)
- [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)
- [Hexo](https://hexo.io/docs/)

Once all the prerequisites are setup, follow the steps below.

1. Open cmd/powershell and run the following commands to clone terraform and build spec file:

```
git clone https://github.com/tduong10101/serverless-blog-terra.git
```
2. Update serverless-blog-terra/variable.tfvars with your github token and site name that you would like set up
3. Run the following commands

```
cd serverless-blog-terra
terraform init
terraform apply -var-file variable.tfvars
```

4. Review the resouces and put in "yes" to approve terraform to spin them up.
5. Grab the outputs and save them somewhere, we'll use them for later steps.
6. Navigate to the parent folder of serverless-blog-terra

```
cd ..
```
8. Create a new folder, give it the same name as git repo (doesn't matter if the is not the same, it's just easier to manage), cd to new folder and run hexo init command
```
mkdir <new folder>
cd .\<new folder>
hexo init
```

7. Copy buildspec.yml file from serverless-blog-terra folder to this new folder
8. Update the buildspec.yml with s3:// link from step 5

10. Init Git and setup git remote with the below commands. Insert your git repo url from step 5.

```
git init
git add *
git commit -m "init"
git remote add origin "<your-git-url-from-step-5>"
git push -u origin master
```

11. Wait for codebuild to complete update S3 bucket. Logon to AWS console to confirm.

{% asset_img codeBuild.JPG %}

12. Open the website_endpoint url on step 5 and enjoy your serverless blog.

Visit [Hexo](https://hexo.io/docs/writing) for instructions on how to create posts, change theme, add plugins etc

Remove the blog:


13. If you don't like the new blog and want to clean up aws/git resources. Run the below command:

```
terraform destroy -var-file variable.tfvars
```

14. Once terraform finish cleaning up the resources. The rest of the folders can be removed from local computer.

