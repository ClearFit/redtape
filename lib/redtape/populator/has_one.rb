module Redtape
  module Populator
    class HasOne < Abstract
      def assign_to_parent
        parent.send("#{association_name}=", model)
      end
    end
  end
end

