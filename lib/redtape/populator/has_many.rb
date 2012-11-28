module Redtape
  module Populator
    class HasMany < Base
      def assign_to_parent
        parent.send(association_name).send("<<", model)
      end
    end
  end
end
