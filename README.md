# Project 05: Deploy Java Web Application on Docker Container using Jenkins Pipeline

Dự án này là tài liệu thực hành hướng dẫn xây dựng một quy trình **CI/CD hoàn chỉnh và tự động** (Continuous Integration/Continuous Deployment) từ đầu. Quy trình này sẽ tự động lấy code từ GitHub, biên dịch ra gói ứng dụng (`.war`), đóng gói ứng dụng đó thành một ảnh Docker (Docker Image) chứa Apache Tomcat 9, và triển khai chạy (Deploy) lên Docker Container trên máy chủ AWS EC2.

---

## 📐 Sơ đồ Kiến trúc & Luồng Hoạt động (CI/CD Workflow)

```text
+------------------+           +--------------------+           +------------------------+
|   Developer      |           |     GitHub         |           |     AWS EC2 Server     |
|  (Local Machine) | --push--> | (Public Repository)| --clone-> |    (Jenkins Server)    |
+------------------+           +--------------------+           +------------------------+
                                                                            |
                                                                   (Jenkins Pipeline)
                                                                            |
                                                                            v
                                                                   +-----------------+
                                                                   |  Stage 1: Clone |
                                                                   +-----------------+
                                                                            |
                                                                            v
                                                                   +-----------------+
                                                                   |  Stage 2: Build | ---> Maven compile (app.war)
                                                                   +-----------------+
                                                                            |
                                                                            v
                                                                   +-----------------+
                                                                   |  Stage 3: Docker| ---> Build Docker Image
                                                                   +-----------------+
                                                                            |
                                                                            v
                                                                   +-----------------+
                                                                   |  Stage 4: Deploy| ---> Run Docker Container
                                                                   +-----------------+      (Expose Port 8087)
```

---

## 🛠️ Các Công nghệ Sử dụng trong Lab
*   **CI/CD Orchestrator**: Jenkins (Declarative Pipeline)
*   **Containerization**: Docker & Dockerfile
*   **Build Tool**: Maven 3.8.8 & Java 11 (App compilation) / Java 21 (Jenkins Engine)
*   **Version Control**: Git & GitHub
*   **Infrastructure**: AWS EC2 Instance (Amazon Linux 2023 / Amazon Linux 2)

---

## 📖 Hướng Dẫn Các Bước Thực Hiện Chi Tiết

### Bước 1: Đẩy mã nguồn dự án lên GitHub
Trước khi cấu hình Jenkins, chúng ta cần đưa toàn bộ code của dự án lên GitHub cá nhân của bạn. Jenkins sẽ truy cập vào đây để tự động lấy code về và chạy pipeline:
```bash
git add .
git commit -m "feat: setup clean pipeline structure"
git push origin main
```

---

### Bước 2: Tạo Máy chủ AWS EC2 và cấu hình Security Group
1. Lên **AWS EC2 Console** -> click **Launch Instance**.
2. **Đặt tên máy chủ**: `jenkins-docker-server`.
3. **OS**: Chọn **Amazon Linux 2023 AMI** hoặc **Amazon Linux 2 AMI**.
4. **Cấu hình Key Pair**: Tạo mới hoặc chọn Key Pair sẵn có dưới dạng `.pem` (ví dụ: `jenkins-docker-key.pem`).
5. **Cấu hình mạng (Network Settings - Click Edit)**:
   * **Security Group Name**: Đổi tên thành `jenkins-docker-sg`.
   * **Inbound Rules**: Cấu hình mở 3 cổng mạng sau:
     * **Cổng 22 (SSH)**: Source type chọn `Anywhere` hoặc `My IP` (để kết nối Terminal từ máy cá nhân).
     * **Cổng 8080 (Jenkins)**: Custom TCP -> Port `8080` từ `Anywhere` (truy cập Web UI của Jenkins).
     * **Cổng 8087 (Web Application)**: Custom TCP -> Port `8087` từ `Anywhere` (để truy cập trang web ứng dụng sau khi deploy).
6. Click **Launch Instance**.

---

### Bước 3: Kết nối SSH vào máy chủ EC2
Mở terminal **Git Bash** ở máy tính cá nhân của bạn, chuyển quyền truy cập file khóa và tiến hành kết nối:
```bash
# Phân quyền đọc cho file khóa (Ví dụ lưu tại ổ D)
chmod 400 /d/Dowload/jenkins-docker-key.pem

# SSH kết nối vào EC2 (dùng IP Public hoặc DNS của máy chủ)
ssh -i /d/Dowload/jenkins-docker-key.pem ec2-user@<YOUR_EC2_PUBLIC_DNS>
```

---

### Bước 4: Tối ưu bộ nhớ ảo (Swap Space) cho EC2 (RẤT QUAN TRỌNG)
Vì máy chủ `t2.micro` mặc định chỉ có 1GB RAM, quá trình Maven compile và Docker build sẽ rất dễ gây nghẽn đĩa và treo máy. Ta tạo thêm 2GB Swap phụ trợ:
```bash
# 1. Tạo file swap dung lượng 2GB
sudo dd if=/dev/zero of=/swapfile bs=1M count=2048

# 2. Phân quyền chỉ cho root truy cập
sudo chmod 600 /swapfile

# 3. Định dạng vùng Swap
sudo mkswap /swapfile

# 4. Kích hoạt
sudo swapon /swapfile

# 5. Thiết lập tự động khởi động Swap khi máy chủ reset (Lệnh gộp có dấu pipe '|')
echo '/swapfile swap swap defaults 0 0' | sudo tee -a /etc/fstab

# 6. Kiểm tra lại RAM và Swap đã hoạt động
free -h
```

---

### Bước 5: Cài đặt Java, Jenkins, Docker và Git
Sau khi cấu hình bộ nhớ ảo xong, copy và chạy lần lượt các lệnh sau trên terminal SSH để cài đặt môi trường chạy:
```bash
# 1. Cập nhật hệ thống
sudo yum update -y

# 2. Cài đặt Git (Cần thiết để Jenkins pull code)
sudo yum install git -y

# 3. Cài đặt Java 21 (Bắt buộc cho công cụ lõi của Jenkins phiên bản mới)
sudo yum install java-21-amazon-corretto -y

# 4. Thêm kho lưu trữ Repository của Jenkins
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key

# 5. Cài đặt Jenkins
sudo yum install jenkins -y

# 6. Start và Kích hoạt Jenkins khởi chạy cùng hệ thống
sudo systemctl enable jenkins
sudo systemctl start jenkins

# 7. Cài đặt Docker
sudo yum install docker -y

# 8. Start và Kích hoạt Docker khởi chạy cùng hệ thống
sudo systemctl enable docker
sudo systemctl start docker

# 9. Thêm user 'jenkins' vào group 'docker'
# Giúp Jenkins có quyền trực tiếp thực hiện lệnh docker build/run mà không cần sudo
sudo usermod -aG docker jenkins

# 10. Restart lại Jenkins để cập nhật quyền group mới
sudo systemctl restart jenkins

# 11. Đọc mật khẩu Admin để mở khóa giao diện Jenkins trên Web
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```
*(Hãy lưu lại chuỗi mật khẩu Admin dài hiển thị sau lệnh số 11 để điền vào trang web).*

---

### Bước 6: Cài đặt và liên kết Maven toàn cục
Chạy các lệnh sau trên terminal SSH để tải Maven 3.8.8 và tạo liên kết (symlink) toàn cục để Jenkins gọi trực tiếp:
```bash
cd /opt
sudo wget https://archive.apache.org/dist/maven/maven-3/3.8.8/binaries/apache-maven-3.8.8-bin.tar.gz
sudo tar -xvzf apache-maven-3.8.8-bin.tar.gz

# Tạo liên kết symlink để lệnh 'mvn' dùng được ở mọi nơi trên máy chủ
sudo ln -s /opt/apache-maven-3.8.8/bin/mvn /usr/bin/mvn

# Kiểm tra hoạt động của Maven
mvn -version
```

---

### Bước 7: Thiết lập Giao diện Web Jenkins
1. Truy cập địa chỉ: `http://<YOUR_EC2_PUBLIC_IP>:8080`.
2. Dán mật khẩu thu được ở **Bước 5** vào để Unlock Jenkins.
3. Click chọn **Install suggested plugins** và chờ các plugin mặc định tải xong.
4. Khởi tạo tài khoản **Admin** đầu tiên (Tên, Mật khẩu, Email) và tiến hành lưu lại.
5. Cấu hình đường dẫn Maven trong Jenkins:
   * Vào **Manage Jenkins** ➔ **Tools** (hoặc *Global Tool Configuration*).
   * Cuộn xuống phần **Maven installations...** và click **Add Maven**:
     * **Name**: Điền đúng tên `Maven 3`.
     * **Bỏ tích** ở ô *Install automatically*.
     * **MAVEN_HOME**: Điền đường dẫn: `/opt/apache-maven-3.8.8`.
   * Click **Save**.

---

### Bước 8: Điều chỉnh cấu hình luồng chạy (Executors) của Node chính
Theo cơ chế mặc định của Jenkins phiên bản mới, số luồng chạy của **Built-in Node** được đặt bằng 0. Chúng ta cần tăng lên để chạy job trực tiếp trên máy chủ:
1. Vào **Manage Jenkins** ➔ **Nodes**.
2. Click chọn **Built-in Node** ➔ click chọn **Configure** ở menu bên trái.
3. Thay đổi giá trị của ô **`Number of executors`** từ `0` thành **`2`**.
4. Tại mục **`Free Temp Space`**:
   * Tích chọn ô vuông **`Don't mark agents temporarily offline`**.
   * Đổi **`Free Space Threshold`** thành `50MiB` và **`Free Space Warning Threshold`** thành `100MiB` (để tránh Jenkins tự động tắt node khi bộ nhớ tạm của `t2.micro` ở mức thấp).
5. Click **Save**.
6. Ở menu bên trái, click chọn nút **`Bring this node online`** (nếu biểu tượng đĩa đơ có dấu X đỏ vẫn hiện).

---

### Bước 9: Tạo và khởi động Pipeline Job
1. Từ trang chủ Jenkins, chọn **New Item**.
2. Đặt tên Job: `hello-world-pipeline`, chọn kiểu **Pipeline** và click **OK**.
3. Cuộn xuống phần **Pipeline** cấu hình:
   * **Definition**: Chọn **Pipeline script from SCM**.
   * **SCM**: Chọn **Git**.
   * **Repository URL**: Điền đường dẫn dự án GitHub của bạn (ví dụ: `https://github.com/QTune1603/Docker-Container-using-Jenkins.git`).
   * **Branch Specifier**: Đổi từ `*/master` thành **`*/main`** (hoặc tên nhánh của bạn).
   * **Script Path**: Giữ nguyên `Jenkinsfile`.
4. Click **Save**.
5. Chọn **Build Now** để chạy và theo dõi quá trình biên dịch, đóng gói Docker và deploy hoàn toàn tự động!

---

### Bước 10: Nghiệm thu và Kiểm thử luồng tự động (CI/CD Verification)
1. **Truy cập ứng dụng**: Truy cập trình duyệt theo địa chỉ: `http://<YOUR_EC2_PUBLIC_IP>:8087` để thưởng thức trang ứng dụng web JSP được thiết kế tuyệt đẹp chạy trên nền Docker.
2. **Kiểm tra luồng tự động**:
   * Vào code dự án của bạn trên máy cá nhân, chỉnh sửa file `index.jsp` (ví dụ sửa tiêu đề).
   * Commit và Push lên GitHub.
   * Lên Jenkins click **Build Now**.
   * Sau khi Job build xong, tải lại trang web cổng `8087` và quan sát thay đổi xuất hiện lập tức mà không cần SSH chỉnh sửa gì thêm!

---

## 🐋 Phân tích Tệp tin Cấu hình chính

### 1. Dockerfile
Tệp tin hướng dẫn Docker cách đóng gói ứng dụng:
*   `FROM tomcat:9.0-jdk11-corretto`: Sử dụng base image là Tomcat 9 chính thức chạy Java 11.
*   `RUN rm -rf /usr/local/tomcat/webapps/*`: Xóa các thư mục ứng dụng mặc định để tránh tranh chấp đường dẫn.
*   `COPY target/hello-world-app.war /usr/local/tomcat/webapps/ROOT.war`: Đóng gói file `.war` của bạn thành ứng dụng gốc `/` (ROOT.war) để khi truy cập không cần thêm đuôi đường dẫn thư mục sau IP.

### 2. Jenkinsfile
File thiết lập Pipeline Declarative tự động hóa các bước:
*   **Stage 1: Clone**: Pull code mới nhất từ GitHub.
*   **Stage 2: Build**: Chạy Maven đóng gói file `.war` (`mvn clean package -DskipTests`).
*   **Stage 3: Docker Build**: Build Docker Image với thẻ tag tương ứng.
*   **Stage 4: Deploy**: Tự động kiểm tra và dọn dẹp các container cũ trùng tên đang chạy, sau đó khởi chạy container mới ở cổng `8087`.
