# Author: Guy Boertje <https://github.com/guyboertje>
# Author: David R. Albrecht <https://github.com/eldavido>
# Author: Hiroshi Ichikawa <http://gimite.net/>
# The license of this source is "New BSD Licence"

require 'google_drive/acl_entry'

module GoogleDrive
  # ACL (access control list) of a spreadsheet.
  #
  # Use GoogleDrive::Spreadsheet#acl to get GoogleDrive::Acl object.
  # See GoogleDrive::Spreadsheet#acl for usage example.
  #
  # This code is based on https://github.com/guyboertje/gdata-spreadsheet-ruby .
  class Acl
    include(Util)
    extend(Forwardable)

    def initialize(session, file) #:nodoc:
      @session = session
      @file = file
      api_permissions = @session.drive.list_permissions(@file.id, fields: '*')
      @entries = api_permissions.permissions.map { |perm| AclEntry.new(perm, self) }
    end

    def_delegators(:@entries, :size, :[], :each)

    # Adds a new entry. +entry+ is either a GoogleDrive::AclEntry or a Hash with keys
    # +:type+, +:email_address+, +:domain+, +:role+ and +:allow_file_discovery+.
    # See GoogleDrive::AclEntry#type and
    # GoogleDrive::AclEntry#role for the document of the fields.
    #
    # Also you can pass the second hash argument +options+, which specifies
    # optional query parameters for the API.
    # Possible keys of +options+ are,
    # * :emailMessage  -- A custom message to include in notification emails
    # * :sendNotificationEmails  -- Whether to send notification emails
    #   when sharing to users or groups.
    #
    # NOTE: This sends email to the new people.
    #
    # e.g.
    #   # A specific user can read or write.
    #   spreadsheet.acl.push(
    #       {type: "user", email_address: "example2@gmail.com", role: "reader"})
    #   spreadsheet.acl.push(
    #       {type: "user", email_address: "example3@gmail.com", role: "writer"})
    #   # Share with a Google Apps domain.
    #   spreadsheet.acl.push(
    #       {type: "domain", domain: "gimite.net", role: "reader"})
    #   # Publish on the Web.
    #   spreadsheet.acl.push(
    #       {type: "anyone", role: "reader"})
    #   # Anyone who knows the link can read.
    #   spreadsheet.acl.push(
    #       {type: "anyone", allow_file_discovery: false, role: "reader"})
    #   # Set ACL without sending notification emails
    #   spreadsheet.acl.push(
    #       {type: "user", email_address: "example2@gmail.com", role: "reader"},
    #       {sendNotificationEmails: false})
    #
    # See here for parameter detais:
    # https://developers.google.com/drive/v3/reference/permissions/create
    def push(params_or_entry, options = {})
      entry = params_or_entry.is_a?(AclEntry) ? params_or_entry : AclEntry.new(params_or_entry)
      api_permission = @session.drive.create_permission(@file.id, entry.params, {fields: '*'}.merge(options))
      new_entry = AclEntry.new(api_permission, self)
      @entries.push(new_entry)
      new_entry
    end

    # Deletes an ACL entry.
    #
    # e.g.
    #   spreadsheet.acl.delete(spreadsheet.acl[1])
    def delete(entry)
      @session.drive.delete_permission(@file.id, entry.id)
      @entries.delete(entry)
    end

    def update_role(entry) #:nodoc:
      api_permission = @session.drive.update_permission(
        @file.id, entry.id, {role: entry.role}, fields: '*')
      entry.api_permission = api_permission
      entry
    end

    def inspect
      "\#<%p %p>" % [self.class, @entries]
    end
  end
end
