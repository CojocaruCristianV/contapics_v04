<template>
  <div class="company-management">
    <h1>Company Management</h1>

    <!-- Company Form -->
    <form @submit.prevent="handleSubmit">
      <input v-model="form.name" placeholder="Company Name" required />
      <input v-model="form.uid" placeholder="Company UID" required />
      <button type="submit">{{ isEditing ? "Update Company" : "Add Company" }}</button>
    </form>

    <!-- Company List -->
    <ul>
      <li v-for="company in companies" :key="company.id">
        {{ company.name }} ({{ company.uid }})
        <button @click="editCompany(company)">Edit</button>
        <button @click="deleteCompany(company.id)">Delete</button>
      </li>
    </ul>
  </div>
</template>

<script>
import axios from "axios";
import { ref, onMounted } from "vue";

export default {
  name: "CompanyManagement",
  setup() {
    const companies = ref([]);
    const form = ref({ name: "", uid: "" });
    const isEditing = ref(false);
    const editingCompanyId = ref(null);

    // Backend URL from environment variable
    const backendUrl = window._env_.BACKEND_URL;

    // Fetch all companies
    const fetchCompanies = async () => {
      try {
        const response = await axios.get(`${backendUrl}/companies`);
        companies.value = response.data;
      } catch (error) {
        console.error("Error fetching companies:", error);
      }
    };

    // Add or update company
    const handleSubmit = async () => {
      try {
        if (isEditing.value) {
          await axios.put(`${backendUrl}/companies/${editingCompanyId.value}`, form.value);
        } else {
          await axios.post(`${backendUrl}/companies`, form.value);
        }
        form.value = { name: "", uid: "" };
        isEditing.value = false;
        editingCompanyId.value = null;
        fetchCompanies();
      } catch (error) {
        console.error("Error saving company:", error);
      }
    };

    // Edit company
    const editCompany = (company) => {
      form.value = { name: company.name, uid: company.uid };
      isEditing.value = true;
      editingCompanyId.value = company.id;
    };

    // Delete company
    const deleteCompany = async (id) => {
      try {
        await axios.delete(`${backendUrl}/companies/${id}`);
        fetchCompanies();
      } catch (error) {
        console.error("Error deleting company:", error);
      }
    };

    onMounted(fetchCompanies);

    return {
      companies,
      form,
      isEditing,
      handleSubmit,
      editCompany,
      deleteCompany,
    };
  },
};
</script>

<style>
/* Add basic styling */
.company-management {
  max-width: 600px;
  margin: 0 auto;
  padding: 20px;
}
form {
  margin-bottom: 20px;
}
input {
  margin-right: 10px;
}
button {
  margin-left: 5px;
}
</style>