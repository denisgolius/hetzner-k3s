require "../util/ssh"
require "../hetzner/server"
require "../hetzner/load_balancer"
require "../configuration/loader"

class Kubernetes::Installer
  getter configuration : Configuration::Loader
  getter masters : Array(Hetzner::Server)
  getter workers : Array(Hetzner::Server)
  getter load_balancer : Hetzner::LoadBalancer?
  getter ssh : Util::SSH

  getter first_master : Hetzner::Server do
    masters[0]
  end

  getter api_server_ip_address : String do
    if masters.size > 1
      load_balancer.not_nil!.public_ip_address.not_nil!
    else
      first_master.public_ip_address.not_nil!
    end
  end

  def initialize(@configuration, @masters, @workers, @load_balancer, @ssh)
  end

  def run
    puts "\n=== Setting up Kubernetes ===\n"

    set_up_first_master
  end

  private def set_up_first_master
    puts "Deploying k3s to first master #{first_master.name}..."

    puts master_install_script(first_master)

    puts "Waiting for the control plane to be ready..."

    # sleep 10

    puts "...k3s has been deployed to first master."
  end

  private def master_install_script(master)
    server_flag = master == first_master ? " --cluster-init " : " --server https://#{api_server_ip_address}:6443 "
    flannel_interface = find_flannel_interface(master)
    puts flannel_interface
  end

  private def find_flannel_interface(server)
    if /Intel/ =~ ssh.run(server, "lscpu | grep Vendor", print_output: false)
      "ens10"
    else
      "enp7s0"
    end
  end
end