require "active_support/core_ext/string/inflections"

module PopuliAPI
  API_TASKS = Set.new(%w[
    addAddress
    addAdvisorToStudent
    addAidApplication
    addApplication
    addApplicationNote
    addAssignmentComment
    addCampusToStudent
    addCommunicationPlanToPerson
    addCourseBulletinBoardPost
    addCourseInstanceAssignment
    addCourseInstanceAssignmentGroup
    addCourseOfferingLink
    addDefaultTuitionScheduleToStudent
    addDonation
    addEmailAddress
    addEnrollment
    addFieldOfStudy
    addFinancialAidAward
    addFinancialAidDisbursement
    addFinancialAidRefund
    addInquiry
    addOrganization
    addOrganizationToPerson
    addPayment
    addPendingCharge
    addPerson
    addPersonRelationship
    addPhoneNumber
    addProfilePicture
    addRole
    addStandardizedTestToStudent
    addStudentDegree
    addStudentDegreeSpecialization
    addStudentProgram
    addTag
    addTermTuitionScheduleToStudent
    addTodo
    addTransferCredit
    addTransferCreditProgram
    addUser
    blockUser
    createCourseInstanceMeeting
    createFinancialAidDisbursementBatch
    deleteAddress
    deleteApplication
    deleteCampusFromStudent
    deleteCommunicationPlanFromPerson
    deleteCourseInstanceAssignment
    deleteCourseInstanceAssignmentGroup
    deleteCourseOfferingLink
    deleteCustomField
    deleteEmailAddress
    deleteFinancialAidAward
    deleteFinancialAidDisbursement
    deleteFinancialAidRefund
    deleteLicensePlate
    deletePersonBirthDate
    deletePersonCitizenship
    deletePersonHometown
    deletePersonOrganization
    deletePersonRaceEthnicity
    deletePersonRelationship
    deletePersonSIN
    deletePersonSSN
    deletePhoneNumber
    deleteStudentDegreeSpecialization
    deleteStudentMealPlan
    deleteStudentRoomPlan
    deleteStudentStandardizedTest
    deleteStudentStandardizedTestSectionScore
    deleteTodo
    downloadBackup
    downloadFile
    downloadStudentSchedule
    editAidApplication
    editDonation
    editFinancialAidAward
    editFinancialAidDisbursement
    editFinancialAidRefund
    editTransferCreditProgram
    finalizeCourseInstance
    getAcademicTerms
    getAcademicYears
    getAidApplication
    getAidApplicationForStudentAidYear
    getAllCustomFields
    getAppeals
    getApplication
    getApplicationFieldOptions
    getApplicationFields
    getApplicationTemplates
    getApplications
    getAssignmentComments
    getAvailableRoles
    getCOACategories
    getCampaigns
    getCampusLifeRooms
    getCampuses
    getCommunicationPlans
    getCountries
    getCourseCatalog
    getCourseGroupInfo
    getCourseGroups
    getCourseInstance
    getCourseInstanceAssignmentGroups
    getCourseInstanceAssignments
    getCourseInstanceFiles
    getCourseInstanceLessons
    getCourseInstanceMeetingAttendance
    getCourseInstanceMeetings
    getCourseInstanceStudent
    getCourseInstanceStudentAttendance
    getCourseInstanceStudents
    getCourseOfferingLinks
    getCourseOfferingSyllabus
    getCurrentAcademicTerm
    getCurrentAcademicYear
    getCustomFieldOptions
    getCustomFields
    getDataSlicerReport
    getDataSlicerReports
    getDegreeAudit
    getDegrees
    getDonation
    getDonor
    getEducationLevels
    getEntriesForAccount
    getEvent
    getEvents
    getFees
    getFileDownloadURL
    getFinancialAidAwardTypes
    getFinancialAidAwards
    getFinancialAidDisbursements
    getFinancialAidYears
    getFunds
    getGradeReport
    getInquiries
    getInquiry
    getInvoice
    getInvoices
    getLeadSources
    getLeads
    getLedgerAccounts
    getMealPlans
    getMyCourses
    getNews
    getOccupations
    getOrganization
    getOrganizationTypes
    getOrganizations
    getPayment
    getPaymentPlans
    getPendingCharges
    getPerson
    getPersonApplications
    getPersonCommunicationPlans
    getPersonLeads
    getPersonLocks
    getPersonOrganizations
    getPersonRelationships
    getPersonSIN
    getPersonSSN
    getPossibleDuplicatePeople
    getPrintLayouts
    getPrograms
    getProvinces
    getRaces
    getRefund
    getRelationshipTypes
    getRoleMembers
    getRoles
    getRoomPlans
    getStandardizedTests
    getStates
    getStudentAssignmentSubmissions
    getStudentBalances
    getStudentDefaultTuitionSchedules
    getStudentDiscipline
    getStudentInfo
    getStudentMealPlan
    getStudentPrograms
    getStudentRoomPlan
    getStudentStandardizedTests
    getStudentTermTuitionSchedules
    getTaggedPeople
    getTags
    getTermBillingInfo
    getTermCourseInstances
    getTermEnrollment
    getTermStudents
    getTodos
    getTransactions
    getTranscript
    getTransferCreditProgramGradeOptions
    getTuitionSchedules
    getUpdatedEnrollment
    getUpdatedPeople
    getUsers
    getVoidedTransactions
    invoicePendingCharges
    linkApplicationToPerson
    linkDonation
    linkInquiryToPerson
    postFinancialAidDisbursement
    removeAdvisorFromStudent
    removeDefaultTuitionScheduleFromStudent
    removeRole
    removeTag
    removeTermTuitionScheduleFromStudent
    removeUser
    requestBackup
    resubscribeEmailAddress
    searchOrganizations
    searchPeople
    setApplicationField
    setCustomField
    setLeadInfo
    setPersonBirthDate
    setPersonCitizenship
    setPersonGender
    setPersonHometown
    setPersonName
    setPersonRaceEthnicity
    setPersonSIN
    setPersonSSN
    setStudentAssignmentGrade
    setStudentEntranceTerm
    setStudentFinalGrade
    setStudentID
    setStudentMealPlan
    setStudentRoomPlan
    setStudentStandardizedTestSectionScore
    setTodoCompleted
    submitApplication
    unblockUser
    unlinkApplication
    unlinkDonation
    unsubscribeEmailAddress
    updateAddress
    updateApplicationFieldStatus
    updateApplicationStatus
    updateCourseInstanceAssignment
    updateCourseInstanceAssignmentGroup
    updateCourseOfferingLink
    updateEmailAddress
    updateInquiry
    updateLicensePlate
    updatePersonOrganization
    updatePhoneNumber
    updateStudentAttendance
    updateStudentCourseEnrollment
    updateStudentStandardizedTest
    updateStudentTermTuitionScheduleBracket
    uploadAssignmentSubmission
    uploadFile
  ])

  PaginatedTask = Struct.new(:task, :record_key_path, :page_or_offset)

  #
  # List of Paginated API Endpoints
  #
  # Some endpoints use page-based pagination, others use offset-based pagination.
  # All of them will return a "num_results" attribute in the top-level <response>.
  #
  # Each task also uses a different tag name for the repeated record.
  #
  PAGINATED_API_TASKS = [
    PaginatedTask.new("getEntriesForAccount", ["ledger_entry"], :page),
    PaginatedTask.new("getInvoices", ["invoices", "invoice"], :page),
    PaginatedTask.new("getLeads", ["lead"], :page),
    PaginatedTask.new("getOrganizations", ["organization"], :page),
    PaginatedTask.new("getPendingCharges", ["pending_charge"], :page),
    PaginatedTask.new("getRoleMembers", ["person"], :page),
    PaginatedTask.new("getStudentBalances", ["student_balance"], :page),
    PaginatedTask.new("getTaggedPeople", ["person"], :page),
    PaginatedTask.new("getTermStudents", ["student"], :page),
    PaginatedTask.new("getTransactions", ["transaction"], :page),
    PaginatedTask.new("getVoidedTransactions", ["transaction"], :page),

    PaginatedTask.new("getApplications", ["application"], :offset),
    PaginatedTask.new("getNews", ["article"], :offset),
    PaginatedTask.new("getUpdatedEnrollment", ["enrollment"], :offset),
    PaginatedTask.new("getUpdatedPeople", ["person"], :offset),
  ].reduce({}) { |acc, pt| acc[pt.task] = pt; acc }.freeze

  module Tasks
    def normalize_task(task)
      as_camel = task.to_s.camelize(:lower).delete_suffix('!')
      do_raise = task.to_s.end_with?('!')
      [as_camel, do_raise]
    end

    def raise_if_task_not_recognized(task)
      raise TaskNotFoundError unless API_TASKS.include? task
    end

    def get_paginated_task(task)
      normalized_task, _ = normalize_task(task)
      PAGINATED_API_TASKS[normalized_task]
    end

    def paginate_task?(task)
      get_paginated_task(task).present?
    end
  end
end
