<template>
  <div class="user-management">
    <h1>User Management</h1>

    <!-- User Form -->
    <form @submit.prevent="handleSubmit">
      <input v-model="form.username" placeholder="Username" required />
      <input v-model="form.password" type="password" placeholder="Password" required />
      <select v-model="form.role">
        <option value="CLIENT">Client</option>
        <option value="CONTABIL">Contabil</option>
      </select>
      <select v-if="form.role === 'CLIENT'" v-model="form.companyId">
        <option v-for="company in companies" :key="company.id" :value="company.id">
          {{ company.name }}
        </option>
      </select>
      <button type="submit">{{ isEditing ? "Update User" : "Add User" }}</button>
    </form>

    <!-- User List -->
    <ul>
      <li v-for="user in users" :key="user.id">
        <span v-if="user.role === 'CLIENT' && user.company">
          {{ user.username }} ({{ user.company.name }})
        </span>
        <span v-else-if="user.role === 'CLIENT'">
          {{ user.username }} - No associated company
        </span>
        <span v-else>
          <i>{{ user.username }}</i>
        </span>
        <button @click="editUser(user)">Edit</button>
        <button @click="deleteUser(user.id)">Delete</button>
      </li>
    </ul>
  </div>
</template>

<script>
import axios from "axios";
import { ref, onMounted } from "vue";

export default {
  name: "UserManagement",
  setup() {
    const users = ref([]);
    const companies = ref([]);
    const form = ref({ username: "", password: "", role: "CLIENT", companyId: null });
    const isEditing = ref(false);
    const editingUserId = ref(null);

    // Backend URL from environment variable
    const backendUrl = window._env_.BACKEND_URL;

    // Fetch all users
    const fetchUsers = async () => {
      try {
        const response = await axios.get(`${backendUrl}/users`);
        users.value = response.data;
      } catch (error) {
        console.error("Error fetching users:", error);
      }
    };

    // Fetch all companies
    const fetchCompanies = async () => {
      try {
        const response = await axios.get(`${backendUrl}/companies`);
        companies.value = response.data;
      } catch (error) {
        console.error("Error fetching companies:", error);
      }
    };

    // Add or update user
    const handleSubmit = async () => {
      try {
        const payload = {
          username: form.value.username,
          password: form.value.password,
          role: form.value.role,
          company: form.value.role === "CLIENT" && form.value.companyId ? { id: form.value.companyId } : undefined,
        };

        if (isEditing.value) {
          await axios.put(`${backendUrl}/users/${editingUserId.value}`, payload);
        } else {
          await axios.post(`${backendUrl}/users`, payload);
        }

        form.value = { username: "", password: "", role: "CLIENT", companyId: null };
        isEditing.value = false;
        editingUserId.value = null;
        fetchUsers();
      } catch (error) {
        console.error("Error saving user:", error);
      }
    };

    // Edit user
    const editUser = (user) => {
      form.value = { username: user.username, password: "", role: user.role, companyId: user.companyId };
      isEditing.value = true;
      editingUserId.value = user.id;
    };

    // Delete user
    const deleteUser = async (id) => {
      try {
        await axios.delete(`${backendUrl}/users/${id}`);
        fetchUsers();
      } catch (error) {
        console.error("Error deleting user:", error);
      }
    };

    // Get company name by ID
    const getCompanyName = (company) => {
      if (company && company.name) {
        return company.name;
      }
      return "Unknown";
    };

    onMounted(() => {
      fetchUsers();
      fetchCompanies();
    });

    return {
      users,
      companies,
      form,
      isEditing,
      handleSubmit,
      editUser,
      deleteUser,
      getCompanyName,
    };
  },
};
</script>

<style>
/* Add basic styling */
.user-management {
  max-width: 600px;
  margin: 0 auto;
  padding: 20px;
}
form {
  margin-bottom: 20px;
}
input, select {
  margin-right: 10px;
}
button {
  margin-left: 5px;
}
</style>