module Pod
  module Generator
    class CopyResourcesScript

      # @return [Array<#to_s>] A list of files relative to the project pods
      #         root.
      #
      attr_reader :resources

      # @return [Platform] The platform of the library for which the copy
      #         resources script is needed.
      #
      attr_reader :platform

      # @param  [Array<#to_s>] resources @see resources
      # @param  [Platform] platform @see platform
      #
      def initialize(resources, platform)
        @resources = resources
        @platform = platform
      end

      # Saves the resource script to the given pathname.
      #
      # @param  [Pathname] pathname
      #         The path where the copy resources script should be saved.
      #
      # @return [void]
      #
      def save_as(pathname)
        pathname.open('w') do |file|
          file.puts(script)
        end
        File.chmod(0755, pathname.to_s)
      end

      private

      # @!group Private Helpers

      # @return [Hash{Symbol=>Version}] The minimum deployment target which
      #         supports the `--reference-external-strings-file` option for
      #         the `ibtool` command.
      #
      EXTERNAL_STRINGS_FILE_MIMINUM_DEPLOYMENT_TARGET = {
        :ios => Version.new('6.0'),
        :osx => Version.new('10.8')
      }

      # @return [Bool] Whether the external strings file is supported by the
      #         `ibtool` according to the deployment target of the platform.
      #
      def use_external_strings_file?
        minimum_deployment_target = EXTERNAL_STRINGS_FILE_MIMINUM_DEPLOYMENT_TARGET[platform.name]
        platform.deployment_target >= minimum_deployment_target
      end

      # @return [String] The install resources shell function.
      #
      def install_resources_function
          if use_external_strings_file?
            CONTENT
          else
            CONTENT.gsub(' --reference-external-strings-file', '')
          end
      end

      # @return [String] The contents of the copy resources script.
      #
      def script
        script = install_resources_function
        resources.each do |resource|
          script += "install_resource '#{resource}'"
        end
        script
      end

      CONTENT = <<EOS
#!/bin/sh

install_resource()
{
  case $1 in
    *\.storyboard)
      echo "ibtool --reference-external-strings-file --errors --warnings --notices --output-format human-readable-text --compile ${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename \\"$1\\" .storyboard`.storyboardc ${PODS_ROOT}/$1 --sdk ${SDKROOT}"
      ibtool --reference-external-strings-file --errors --warnings --notices --output-format human-readable-text --compile "${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename \\"$1\\" .storyboard`.storyboardc" "${PODS_ROOT}/$1" --sdk "${SDKROOT}"
      ;;
    *\.xib)
        echo "ibtool --reference-external-strings-file --errors --warnings --notices --output-format human-readable-text --compile ${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename \\"$1\\" .xib`.nib ${PODS_ROOT}/$1 --sdk ${SDKROOT}"
      ibtool --reference-external-strings-file --errors --warnings --notices --output-format human-readable-text --compile "${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename \\"$1\\" .xib`.nib" "${PODS_ROOT}/$1" --sdk "${SDKROOT}"
      ;;
    *.framework)
      echo "rsync -rp ${PODS_ROOT}/$1 ${CONFIGURATION_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
      rsync -rp "${PODS_ROOT}/$1" "${CONFIGURATION_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
      ;;
    *.xcdatamodeld)
      echo "xcrun momc ${PODS_ROOT}/$1 ${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename $1 .xcdatamodeld`.momd"
      xcrun momc "${PODS_ROOT}/$1" "${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename $1 .xcdatamodeld`.momd"
      ;;
    *)
      echo "rsync -av --exclude '*/.svn/*' ${PODS_ROOT}/$1 ${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
      rsync -av --exclude '*/.svn/*' "${PODS_ROOT}/$1" "${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
      ;;
  esac
}
EOS

    end
  end
end
