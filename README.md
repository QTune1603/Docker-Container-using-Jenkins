# Project 05: Deploy Code on Docker Container using Jenkins

Dự án này hướng dẫn tự động hóa quy trình Build, Đóng gói (Containerize) và Triển khai (Deploy) ứng dụng Java Web vào Docker container thông qua Jenkins Pipeline trên AWS.

---

## 🏗️ Cấu trúc Thư mục Dự án

```text
Docker-Container-using-Jenkins/
├── Dockerfile          # Cấu hình build ảnh Docker chạy Tomcat 9
├── Jenkinsfile         # Jenkins Pipeline (Build -> Docker Build -> Deploy)
├── pom.xml             # Quản lý thư viện và cấu hình build Maven
├── README.md           # Hướng dẫn chi tiết này
└── src/
    └── main/
        └── webapp/
            ├── index.jsp        # Giao diện chính của ứng dụng
            └── WEB-INF/
                └── web.xml      # Cấu hình servlet của ứng dụng
```

---

## 🛠️ Hướng dẫn Từng Bước Thực Hành Lab

Có 2 cách triển khai môi trường Lab này:
*   **Cách 1 (Khuyên dùng - Đơn giản & Hiện đại)**: Cài cả Jenkins và Docker trên **cùng 1 máy chủ EC2 Instance**. Jenkins chạy lệnh docker cục bộ để build và deploy.
*   **Cách 2 (Theo tài liệu gốc)**: Cài Jenkins trên EC2 Instance A, Docker Host trên EC2 Instance B. Kết nối hai máy qua SSH và plugin `Publish Over SSH`.

Dưới đây là hướng dẫn chi tiết cho **Cách 1** (sử dụng Jenkinsfile Declarative Pipeline hiện đại).

### Bước 1: Khởi tạo Máy chủ EC2 và Cài đặt Jenkins
1. Khởi tạo một instance EC2 Linux (khuyên dùng Amazon Linux 2 hoặc Ubuntu), loại instance `t2.micro` hoặc `t2.medium` (nếu muốn build nhanh hơn).
2. Mở cổng **8080** (cho Jenkins) và **8087** (cho Ứng dụng mẫu sau khi Docker deploy) trong Security Group.
3. Cài đặt Java 11 và Jenkins:
   ```bash
   # Cài đặt Java 11
   sudo yum install java-11-amazon-corretto -y

   # Thêm repo Jenkins và cài đặt
   sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
   sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
   sudo yum install jenkins -y

   # Start Jenkins
   sudo systemctl enable jenkins
   sudo systemctl start jenkins
   ```
4. Truy cập giao diện Web Jenkins tại địa chỉ `http://<EC2_PUBLIC_IP>:8080`.
5. Lấy mật khẩu admin khởi tạo bằng lệnh:
   ```bash
   sudo cat /var/lib/jenkins/secrets/initialAdminPassword
   ```
6. Cài đặt các plugin mặc định được gợi ý (Install suggested plugins).

### Bước 2: Cài đặt Docker và Cấp quyền cho Jenkins
1. Cài đặt Docker trên chính máy chủ EC2 đó:
   ```bash
   sudo yum update -y
   sudo yum install docker -y
   sudo systemctl enable docker
   sudo systemctl start docker
   ```
2. **Quan trọng**: Cấp quyền chạy Docker cho user `jenkins` để Jenkins có thể gọi lệnh `docker build` và `docker run` mà không cần quyền root/sudo:
   ```bash
   sudo usermod -aG docker jenkins
   # Restart lại Jenkins để cập nhật quyền group mới
   sudo systemctl restart jenkins
   ```

### Bước 3: Cấu hình Maven trên Jenkins Server
1. Cài đặt Maven vào thư mục `/opt`:
   ```bash
   cd /opt
   sudo wget https://archive.apache.org/dist/maven/maven-3/3.8.8/binaries/apache-maven-3.8.8-bin.tar.gz
   sudo tar -xvzf apache-maven-3.8.8-bin.tar.gz
   ```
2. Cấu hình biến môi trường Maven trong `/etc/profile` hoặc cấu hình trực tiếp qua giao diện Jenkins:
   * Vào **Manage Jenkins** -> **Global Tool Configuration** (hoặc **Tools** ở phiên bản mới).
   * Tại mục **Maven installations**: Click **Add Maven**.
     * Đặt tên là: `Maven 3` (hoặc tên bất kỳ bạn muốn).
     * Bỏ chọn *Install automatically*.
     * Nhập **MAVEN_HOME**: `/opt/apache-maven-3.8.8`.
   * Nhấn **Save**.

### Bước 4: Tạo Job Pipeline trên Jenkins
1. Tại màn hình chính Jenkins, chọn **New Item**.
2. Đặt tên Job (ví dụ: `Project-05-Docker-Deployment`), chọn kiểu **Pipeline** và click **OK**.
3. Tại phần cấu hình Job:
   * Cuộn xuống phần **Pipeline**.
   * Tại mục *Definition*, chọn **Pipeline script from SCM**.
   * Tại mục *SCM*, chọn **Git**.
   * Nhập **Repository URL**: Đường dẫn repo GitHub của bạn (ví dụ: `https://github.com/<tên-user>/Docker-Container-using-Jenkins.git`).
   * Chọn **Branch Specifier** là: `*/main` (hoặc branch chính của bạn).
   * Tại mục *Script Path*, giữ nguyên là `Jenkinsfile`.
4. Nhấp **Save**.

### Bước 5: Chạy Pipeline & Kiểm tra Kết quả
1. Click **Build Now** trên Jenkins để kích hoạt Pipeline.
2. Theo dõi các Stage chạy qua giao diện Pipeline:
   * **Stage 1 (Clone)**: Jenkins kéo code từ repo GitHub của bạn về workspace.
   * **Stage 2 (Build)**: Jenkins chạy `mvn clean package` để build ra file `target/hello-world-app.war`.
   * **Stage 3 (Docker Build)**: Build Docker image từ Dockerfile cục bộ.
   * **Stage 4 (Deploy)**: Dọn dẹp container cũ (nếu có) và chạy container mới bằng lệnh:
     `docker run -d --name webapp-container -p 8087:8080 hello-world-app:latest`
3. Sau khi Pipeline báo xanh (Success), hãy truy cập trình duyệt tại địa chỉ:
   👉 **`http://<EC2_PUBLIC_IP>:8087`**

Bạn sẽ thấy màn hình giao diện Web đen bóng vô cùng hiện đại, thông báo rằng ứng dụng Java của bạn đã được đóng gói và triển khai thành công!

---

## 💾 Đẩy code lên GitHub
Để chạy thử pipeline, trước hết hãy đẩy toàn bộ cấu trúc code này lên GitHub của bạn:
```bash
git add .
git commit -m "feat: setup clean project 5 with Dockerfile, Jenkinsfile and simple webapp"
git push origin main
```
