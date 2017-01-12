#
# Cookbook: consul
# License: Apache 2.0
#
# Copyright 2014-2016, Bloomberg Finance L.P.
#
require 'poise'
require_relative './helpers'

module ConsulCookbook
  module Provider
    # A `consul_installation` provider which manages Consul binary
    # installation from remote source URL.
    # @action create
    # @action remove
    # @provides consul_installation
    # @example
    #   consul_installation '0.5.0'
    # @since 2.0
    class ConsulInstallationBinary < Chef::Provider
      include Poise(inversion: :consul_installation)
      include ::ConsulCookbook::Helpers
      provides(:binary)
      inversion_attribute('consul')

      # @api private
      def self.provides_auto?(_node, _resource)
        true
      end

      # Set the default inversion options.
      # @return [Hash]
      # @api private
      def self.default_inversion_options(node, resource)
        extract_path = node.windows? ? node.config_prefix_path : '/opt/consul'
        super.merge(extract_to: extract_path,
                    version: resource.version,
                    archive_url: 'https://releases.hashicorp.com/consul/%{version}/%{basename}',
                    archive_basename: binary_basename(node, resource),
                    archive_checksum: binary_checksum(node, resource))
      end

      def action_create
        notifying_block do
          directory join_path(options[:extract_to], new_resource.version) do
            mode '0755'
            recursive true
          end

          url = options[:archive_url] % {version: options[:version], basename: options[:archive_basename]}
          poise_archive url do
            destination join_path(options[:extract_to], new_resource.version)
            source_properties checksum: options[:archive_checksum]
            strip_components 0
            not_if { ::File.exist?(consul_program) }
          end

          link '/usr/local/bin/consul' do
            to ::File.join(options[:extract_to], new_resource.version, 'consul')
            not_if { windows? }
          end
        end
      end

      def action_remove
        notifying_block do
          directory join_path(options[:extract_to], new_resource.version) do
            action :delete
            recursive true
          end
        end
      end

      def consul_program
        @program ||= join_path(options[:extract_to], new_resource.version, 'consul')
        windows? ? @program + '.exe' : @program
      end

      def self.binary_basename(node, resource)
        case node['kernel']['machine']
        when 'x86_64', 'amd64' then ['consul', resource.version, node['os'], 'amd64'].join('_')
        when /i\d86/ then ['consul', resource.version, node['os'], '386'].join('_')
        when /^arm/ then ['consul', resource.version, node['os'], 'arm'].join('_')
        else ['consul', resource.version, node['os'], node['kernel']['machine']].join('_')
        end.concat('.zip')
      end

      def self.binary_checksum(node, resource)
        tag = node['kernel']['machine'] =~ /x86_64/ ? 'amd64' : node['kernel']['machine']
        case [node['os'], tag].join('-')
        when 'darwin-amd64'
          case resource.version
          when '0.5.0' then '24d9758c873e9124e0ce266f118078f87ba8d8363ab16c2e59a3cd197b77e964'
          when '0.5.1' then '161f2a8803e31550bd92a00e95a3a517aa949714c19d3124c46e56cfdc97b088'
          when '0.5.2' then '87be515d7dbab760a61a359626a734f738d46ece367f68422b7dec9197d9eeea'
          when '0.6.0' then '29ddff01368458048731afa586cec5426c8033a914b43fc83d6442e0a522c114'
          when '0.6.1' then '358654900772b3477497f4a5b5a841f2763dc3062bf29212606a97f5a7a675f3'
          when '0.6.2' then '3089f77fcdb922894456ea6d0bc78a2fb60984d1d3687fa9d8f604b266c83446'
          when '0.6.3' then '6dff4ffc61d66aacd627a176737b8725624718a9e68cc81460a3df9b241c7932'
          when '0.6.4' then '75422bbd26107cfc5dfa7bbb65c1d8540a5193796b5c6b272d8d70b094b26488'
          when '0.7.0' then '74111674527c5be0db7a98600df8290395abdd94e2cd86bda7418d748413396d'
          when '0.7.1' then '9b3a199779a0d9b92266fae2abd7ed91c18ba437eba46e76114cd1940b3b7741'
          when '0.7.2' then '4403357fbfddbcdd0742946cab7856638cb0f15898c75d79d155753621d60b0c'
          end
        when 'darwin-i386'
          case resource.version
          when '0.6.0' then '95d57bfcc287bc344ec3ae8372cf735651af1158c5b1345e6f30cd9a9c811815'
          when '0.6.1' then '41dfcc0aefe0a60bdde413eaa8a4a0c98e396d6b438494f1cf29b32d07759b8e'
          when '0.6.2' then '973105816261c8001fcfa76c9fb707fa56325460476fb0daa97b9ece0602a918'
          when '0.6.3' then '7fb30756504cd9559c9b23e5d0d8d73a847ee62ed85d39955b5906c2f59a5bc1'
          when '0.6.4' then '4cd39e968ca6bed0888f831a2fc438ffe0b48dab863c822e777f5b5219bacf5c'
          when '0.7.0' then '16ab91969c9b268ccae532070221b6c4fecaad298e4662a46cdfe9847c80dd3f'
          when '0.7.1' then '668b0a5c577fc717de710391fa509a820c5640d73ab3b232023fc351e6084c36'
          when '0.7.2' then '23e6e8dd14c2be02fd095a865edd1725f5ccdbce1109ad5f70832866012d1d7f'
          end
        when 'solaris-amd64'
          case resource.version
          when '0.6.2' then 'f5655f0b173e5d51c5b92327d1fc7f24ac0939897a1966da09146e4eb75af9d1'
          when '0.6.3' then 'e6a286ff17a2345b8800732850eadb858b3dba9486355e1164a774ccec2f0e98'
          when '0.6.4' then 'c26a64310f83c3ba388c78d5b89d640d961ae9eabe221c244bfffcfa753966bd'
          when '0.7.0' then '0f1db173a95861bc84940b4dcdb2debfbfbc18f2b50e651d0e23dfda331018ea'
          when '0.7.1' then '9c77c5c904dce4832b9e7dede2cdc5f42f5fb360885583bc414fee868aed5cb9'
          when '0.7.2' then 'f1ccaf9d9dd62544323e130cee7221df2a6d4b577e9e4a120db357e59782f12d'
          end
        when 'windows-amd64'
          case resource.version
          when '0.6.0' then '182beea0d8d346a9bfd70679621a5542aeeeea1f35be81fa3d3aeec2479bac3d'
          when '0.6.1' then '2be6b0f0fdebff00aea202e9846131af570676f52e2936728cbf29ffbb02f57f'
          when '0.6.2' then 'df3234fb7def7138b7cb8c73fe7c05942ec1e485925701a7b38fc7e2396a212f'
          when '0.6.3' then '04cd1fdc9cd3a27ffc64e312e40142db7af0d240608f8080ec6d238294b20652'
          when '0.6.4' then '1ca3cc2943b27ec8968665efce1122d4ea355ccbde5b4807753af71f11190a9b'
          when '0.7.0' then 'ac5973a58dd9c6f52c784a7106a29adcf7c94015036538155b6c0ee7efc3a330'
          when '0.7.1' then '71a4e073cbab336c0becb5c17a0173fdae56480558564138353dc0b89e989d82'
          when '0.7.2' then '7a5ec31018328a3764f22327c940765c9cd99e57c6759fc43fbfed8318d5e379'
          end
        when 'windows-i386'
          case resource.version
          when '0.5.0' then '7fd760ee8a5c2756391cacc1e924ae602b16cdad838db068e564f798383ad714'
          when '0.5.1' then 'bb9e1753cf793ad6f9db34bd6e18fb0fa5b0696a8a51a7f1c61484386dfe6682'
          when '0.5.2' then '2e866812de16f1a6138a0fd1eebc76143f1314826e3b52597a55ac510ae94be6'
          when '0.6.0' then '8379afd07668933c120880bba8228277e380abb14e07a6c45b94562ac19b37bd'
          when '0.6.1' then '10197d1f7be0d0087414c9965008ddd88e9fcd9ac9d5bd02d72d65eda36f5834'
          when '0.6.2' then 'f072d89c098dde143897e653d5adaf23125b58062344ef4be4029d635f959654'
          when '0.6.3' then '55733a730c5055d0ed1dc2656b2b6a27b21c7c361a907919cfae90aab2dff870'
          when '0.6.4' then '6555f0fff6c3f9ea310c94a73365d9892afc255efb47c85041ad1c0ede854b87'
          when '0.7.0' then 'd0ddfe7d1de9879f02b0d110e45bb74cd5028a2910bcac8b2629d0659367cd96'
          when '0.7.1' then 'ad7b76ac8660c7417bbdccbe1905942fa2fcc4c53a093d7b2d64497bdf4fc315'
          when '0.7.2' then 'c041dc43995df3505d9146e3a2f532bfc491c49fb644bd1e2ceead7d7dc3011c'
          end
        when 'linux-amd64'
          case resource.version
          when '0.5.0' then '161f2a8803e31550bd92a00e95a3a517aa949714c19d3124c46e56cfdc97b088'
          when '0.5.1' then '967ad75865b950698833eaf26415ba48d8a22befb5d4e8c77630ad70f251b100'
          when '0.5.2' then '171cf4074bfca3b1e46112105738985783f19c47f4408377241b868affa9d445'
          when '0.6.0' then '307fa26ae32cb8732aed2b3320ed8daf02c28b50d952cbaae8faf67c79f78847'
          when '0.6.1' then 'dbb3c348fdb7cdfc03e5617956b243c594a399733afee323e69ef664cdadb1ac'
          when '0.6.2' then '7234eba9a6d1ce169ff8d7af91733e63d8fc82193d52d1b10979d8be5c959095'
          when '0.6.3' then 'b0532c61fec4a4f6d130c893fd8954ec007a6ad93effbe283a39224ed237e250'
          when '0.6.4' then 'abdf0e1856292468e2c9971420d73b805e93888e006c76324ae39416edcf0627'
          when '0.7.0' then 'b350591af10d7d23514ebaa0565638539900cdb3aaa048f077217c4c46653dd8'
          when '0.7.1' then '5dbfc555352bded8a39c7a8bf28b5d7cf47dec493bc0496e21603c84dfe41b4b'
          when '0.7.2' then 'aa97f4e5a552d986b2a36d48fdc3a4a909463e7de5f726f3c5a89b8a1be74a58'
          end
        when 'linux-i386'
          case resource.version
          when '0.5.0' then '4b6147c30596a30361d4753d409f8a1af9518f54f5ed473a4c4ac973738ac0fd'
          when '0.5.1' then 'dad93a02c01de885daee191bcc5a05ca2bf106200da61db33694a658432d8399'
          when '0.5.2' then '29306ce398109f954ceeea3af79878be4fb0d949f8af3a27c95ccef2101e8f60'
          when '0.6.0' then 'f58f3f03a8b48d89bb8be94a6d1767393ad2a410c920b064066e01c7fa24f06c'
          when '0.6.1' then '34b8d4a2a9ec85082b6e93c6785ba9c54663fec414062e45dd4386db46a533c4'
          when '0.6.2' then '500ac8c75768b7f2d63521d2501ff8cc5fb7f9ddf6c550e9449364810c96f419'
          when '0.6.3' then '2afb65383ab913344daaa9af827c1e8576c7cae16e93798048122929b6e4cc92'
          when '0.6.4' then 'dbaf5ad1c95aa7dce1625d61b6686d3775e53cb3e7d6c426d29ea96622d248a8'
          when '0.7.0' then 'babf618b1f10455b4ab65b91bdf5d5a7be5bfbb874ce41e8051caca884c43378'
          when '0.7.1' then '7a391a9adc251a5889405eab5512668b77e6ac0f7d818852928735fa82e8abad'
          when '0.7.2' then '43b22bcd04e74445c3ea6c143b3acbfe5546d6792c28d123ef5832cd8f96162f'
          end
        when 'linux-arm'
          case resource.version
          when '0.6.0' then '425e7332789deb446a486ac25f7143aba5f16453ac46ede39b71ab6a361d8726'
          when '0.6.1' then '5b61e9ed10e02990aa8a2a0116c398c61608bc7f5051cb5a13750ffd47a54d51'
          when '0.6.2' then 'b6b4f66f6dd8b1d4ebbd0339f4ed78c4853c7bd0d42fd15af70179b5bc65482e'
          when '0.6.3' then 'c5fd5278be2757d2468bc7e263af15bc9a9e80fc5108fec658755804ea9bca56'
          when '0.6.4' then '81200fc8b7965dfc6048c336925211eaf2c7247be5d050946a5dd4d53ec9817e'
          when '0.7.0' then '7c9ee149d66d14cc8aa81b8d86e7df5a27876216578ab841ab3921e7f4a0ce4b'
          when '0.7.1' then 'e7b6846fb338c31e238f9b70cc42bd35f7de804cc31d2d91fe23cbe5de948aae'
          when '0.7.2' then 'e18934a3a38b980bc0cfaa8d74379a6bfe58cf1ecf4b164e28ff37dd6c7198b0'
          end
        when 'freebsd-amd64'
          case resource.version
          when '0.6.0' then 'd7be5c95b971f48ccbd2c53c342dced9a3d0a5bc58f57b4f2e75672d96929923'
          when '0.6.1' then '04688dfabedf6ded7f3d548110c7d9ffc8d6d3a091062593e421702bc42b465d'
          when '0.6.2' then '1ccf96cb58c6fa927ee21c24d9be368ebe91559ed32626a89a715a3781659e3f'
          when '0.6.3' then '8bdf2da41e6118af18af9aba0a127d4abb3453a20a9064e1bd1206f5c11ac2c8'
          when '0.6.4' then 'fe0b04a2111c6274e79cc86a91b48cb63879f0badd4d6dc848cb7105a572c7fd'
          when '0.7.0' then '54c864ce0deeeb01d10752a787c3bc3154d6fb020859fcc8b089ac3548756702'
          when '0.7.1' then '841e0c3406b967bef2e763d57d2827169e63156f972a1cc7894deb6d98a998d3'
          when '0.7.2' then '2989fc85d8784ad658d42064d0b97a86efc34a8cff4c18c9a68604e43b44e665'
          end
        when 'freebsd-i386'
          case resource.version
          when '0.6.0' then 'c5eb9f5c211612148e1e1cd101670fd08fd1abf9b2e541ac2936ab9637626249'
          when '0.6.1' then '87d8c56c0c02e2fcde5192614dff9c491af93f7186fd55caae3fbe2c4d6ca80c'
          when '0.6.2' then 'fc87f2ddd2090031e79136954d9e3f85db480d5ed9eba6ae627bf460e4c95e6e'
          when '0.6.3' then '4a1aa8f570852eb238b7406172c097f5b32f41a3f01186111e576faa7506248c'
          when '0.6.4' then 'c2d0f7d5f785a83eeb962209a35ebb577b41c7f8cb1f78bf68a42e8f8be77d22'
          when '0.7.0' then 'fe7f80ce8fcdd517f4228b66a4836119ad6e22c2a5285cf4de02c0ccf8c2eefd'
          when '0.7.1' then 'ec4abcc0d16b480a59a7efec7533fdb0925d96b1f9d1034eac4e1648f7c5b749'
          when '0.7.2' then 'b4cae7c51716dbff399e52881422218ccbca3aa02f6db5b87da41eccb9dd8f8f'
          end
        when 'freebsd-arm'
          case resource.version
          when '0.6.0' then '92f29ad00f8f44d3be43b3b038a904c332757eb2a6848a7d6754583c2791e18b'
          when '0.6.1' then '7b907fbd4377671de1be2dc0c19f955e1b37cd862c1af8251e9bf6d668b0d3a8'
          when '0.6.2' then '30d8d09dd88cdd8d5256cea445fd0fed787d73cc6585e2eef7212161f29c8053'
          when '0.6.3' then '5452d29f1cf0720c4ae0e0ec1cc5e44b0068a0340a6b61ab5ec245fa0f3447ad'
          when '0.6.4' then 'edf3862e3fef6a48ede1d2671fe6b8da8891ca57bd5381b8a19d8d1b68e4d5da'
          when '0.7.0' then '1b16624f3581a7bef5328d17ff4ab9188ffdd07543cab3fb72b3cd7a7d469724'
          when '0.7.1' then '4e32d717f8699b7f3b2ce6bd5b5d04ef63cfce5509ad185b996e9cf35518f7fe'
          when '0.7.2' then 'f86fa7f17a37a8e8047cd7b7bb10c8ee42d3a201c0fa527650331e9ad4e92203'
          end
        end
      end
    end
  end
end
