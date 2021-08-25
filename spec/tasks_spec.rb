RSpec.describe PopuliAPI::Tasks do
  subject { Class.new { extend PopuliAPI::Tasks } }

  describe "normalize_task(task)" do
    it "returns an array with the task formatted as camel case at index 0" do
      expect(subject.normalize_task("snake_case").first).to eq("snakeCase")
      expect(subject.normalize_task("camelCase").first).to eq("camelCase")
    end

    it "returns an array with do_raise? at index 1 (true if request should raise)" do
      expect(subject.normalize_task("safe").last).to be(false)
      expect(subject.normalize_task("danger!").last).to be(true)
    end
  end

  describe "raise_if_task_not_recognized(task)" do
    it "raises a TaskNotFoundError if task is not in the allow list" do
      expect { subject.raise_if_task_not_recognized("getPerson") }.to_not raise_error
      expect { subject.raise_if_task_not_recognized("notATask") }.to \
        raise_error(PopuliAPI::TaskNotFoundError)
    end
  end

  describe "get_paginated_task(task)" do
    it "returns the PaginatedTask item matching the task name" do
      expect(subject.get_paginated_task("getInvoices")).to \
        be(PopuliAPI::PAGINATED_API_TASKS["getInvoices"])
    end
  end

  describe "paginate_task?(task)" do
    it "returns true if the task returns a paginated response" do
      expect(subject.paginate_task?("getApplications")).to be(true)
      expect(subject.paginate_task?("getPerson")).to be(false)
      expect(subject.paginate_task?("getData")).to be(false)
    end
  end
end
