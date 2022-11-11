terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  zone      = "ru-central1-a"
}


resource "yandex_compute_image" "ubuntu_2004" {
  source_family = "ubuntu-2004-lts"
}

resource "yandex_compute_image" "centos-7" {
  source_family = "centos-7"
}

#Create VM-1, установка nginx средставми ansible 
resource "yandex_compute_instance" "node-1-ubuntu" {
  name = "ubuntu"

  resources {
    cores  = 2
    memory = 2

}
  boot_disk {
    initialize_params {
      image_id = yandex_compute_image.ubuntu_2004.id
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    nat       = true
  }
  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
 
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/.ssh/id_rsa")
    host        = yandex_compute_instance.node-1-ubuntu.network_interface.0.nat_ip_address
  }
  provisioner "remote-exec" {
    inline = ["echo 'Im ready!'"]

  }

  provisioner "local-exec" {
    command = "ansible-playbook -u ubuntu -i '${self.network_interface.0.nat_ip_address},' --private-key ~/.ssh/id_rsa nginx.yml"
  }


   
}


resource "yandex_vpc_network" "network-1" {
  name = "network1"
}

resource "yandex_vpc_subnet" "subnet-1" { 
  name = "subnet-1"
  zone = "ru-central1-a"
  network_id = yandex_vpc_network.network-1.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

#Create VM-2, установка nginx стредставми Cloudinit
resource "yandex_compute_instance" "node-2-centos" { 
  name = "centos"

 resources {
   cores = 2
   memory = 2
 }

 boot_disk {
     initialize_params {
      image_id = yandex_compute_image.centos-7.id
    }
 }
  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    nat       = true
  }



  metadata = {
    #ssh-keys = "centos:${file("~/.ssh/id_rsa.pub")}"
    user-data = "${file("user-data.yml")}"
 }

}
output "internal_ip_address_node_1_ubuntu" {
  value = yandex_compute_instance.node-1-ubuntu.network_interface.0.ip_address
}

output "internal_ip_address_ndeo_2_centos" {
  value = yandex_compute_instance.node-2-centos.network_interface.0.ip_address
}

output "external_ip_address_node_1_ubuntu" {
  value = yandex_compute_instance.node-1-ubuntu.network_interface.0.nat_ip_address
}

output "external_ip_address_ndeo_2_centos" {
  value = yandex_compute_instance.node-2-centos.network_interface.0.nat_ip_address
}

output "subnet-1" {
  value = yandex_vpc_subnet.subnet-1.id
}

