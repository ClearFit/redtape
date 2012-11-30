module Redtape
  module Populator
    class Root < Abstract
      def initialize(args = {})
        super
      end

      def assign_to_parent
        # no-op
      end
    end
  end
end
