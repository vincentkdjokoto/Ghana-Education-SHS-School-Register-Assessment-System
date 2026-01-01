// API Configuration
const API_BASE_URL = window.location.hostname === 'localhost' 
    ? 'http://localhost:5000/api'
    : '/api';

// API Service
const apiService = {
    // Headers configuration
    getHeaders() {
        const token = localStorage.getItem('authToken');
        return {
            'Content-Type': 'application/json',
            'Authorization': token ? `Bearer ${token}` : ''
        };
    },

    // Handle API response
    async handleResponse(response) {
        if (!response.ok) {
            const error = await response.json().catch(() => ({
                message: `HTTP error! status: ${response.status}`
            }));
            throw new Error(error.message || 'An error occurred');
        }
        return response.json();
    },

    // Generic request method
    async request(endpoint, options = {}) {
        const url = `${API_BASE_URL}${endpoint}`;
        const config = {
            ...options,
            headers: this.getHeaders()
        };

        try {
            const response = await fetch(url, config);
            return await this.handleResponse(response);
        } catch (error) {
            console.error('API Request failed:', error);
            throw error;
        }
    },

    // Student APIs
    students: {
        getAll: (params = '') => apiService.request(`/students${params}`),
        getById: (id) => apiService.request(`/students/${id}`),
        create: (data) => apiService.request('/students', {
            method: 'POST',
            body: JSON.stringify(data)
        }),
        update: (id, data) => apiService.request(`/students/${id}`, {
            method: 'PUT',
            body: JSON.stringify(data)
        }),
        delete: (id) => apiService.request(`/students/${id}`, {
            method: 'DELETE'
        }),
        search: (query) => apiService.request(`/students/search?q=${query}`),
        getByClass: (className) => apiService.request(`/students/class/${className}`),
        getByProgramme: (programme) => apiService.request(`/students/programme/${programme}`)
    },

    // Assessment APIs
    assessments: {
        getAll: (params = '') => apiService.request(`/assessments${params}`),
        getById: (id) => apiService.request(`/assessments/${id}`),
        create: (data) => apiService.request('/assessments', {
            method: 'POST',
            body: JSON.stringify(data)
        }),
        update: (id, data) => apiService.request(`/assessments/${id}`, {
            method: 'PUT',
            body: JSON.stringify(data)
        }),
        delete: (id) => apiService.request(`/assessments/${id}`, {
            method: 'DELETE'
        }),
        getByStudent: (studentId) => apiService.request(`/assessments/student/${studentId}`),
        getByClass: (className, term, year) => 
            apiService.request(`/assessments/class/${className}/${term}/${year}`),
        calculatePromotion: (data) => apiService.request('/assessments/promotion', {
            method: 'POST',
            body: JSON.stringify(data)
        }),
        getClassAverage: (className, term, year) => 
            apiService.request(`/assessments/average/${className}/${term}/${year}`)
    },

    // Report APIs
    reports: {
        getHeadmasterReport: (term, year) => 
            apiService.request(`/reports/headmaster/${term}/${year}`),
        getClassReport: (className, term, year) => 
            apiService.request(`/reports/class/${className}/${term}/${year}`),
        getStudentReport: (studentId, term, year) => 
            apiService.request(`/reports/student/${studentId}/${term}/${year}`),
        generateReportCard: (studentId, term, year) => 
            apiService.request(`/reports/generate/${studentId}/${term}/${year}`),
        exportToExcel: (className, term, year) => 
            apiService.request(`/reports/export/${className}/${term}/${year}`),
        getStatistics: () => apiService.request('/reports/statistics'),
        getPromotionReport: (term, year) => 
            apiService.request(`/reports/promotion/${term}/${year}`)
    },

    // Dashboard APIs
    dashboard: {
        getOverview: () => apiService.request('/dashboard/overview'),
        getRecentActivity: () => apiService.request('/dashboard/activity'),
        getPerformanceTrends: () => apiService.request('/dashboard/trends'),
        getProgrammeStats: () => apiService.request('/dashboard/programmes')
    },

    // Auth APIs
    auth: {
        login: (credentials) => apiService.request('/auth/login', {
            method: 'POST',
            body: JSON.stringify(credentials)
        }),
        register: (userData) => apiService.request('/auth/register', {
            method: 'POST',
            body: JSON.stringify(userData)
        }),
        logout: () => apiService.request('/auth/logout'),
        refreshToken: () => apiService.request('/auth/refresh')
    },

    // File upload
    upload: {
        studentPhoto: (studentId, file) => {
            const formData = new FormData();
            formData.append('photo', file);
            
            return fetch(`${API_BASE_URL}/upload/student/${studentId}/photo`, {
                method: 'POST',
                body: formData,
                headers: {
                    'Authorization': `Bearer ${localStorage.getItem('authToken')}`
                }
            });
        },
        bulkStudents: (file) => {
            const formData = new FormData();
            formData.append('file', file);
            
            return fetch(`${API_BASE_URL}/upload/students/bulk`, {
                method: 'POST',
                body: formData,
                headers: {
                    'Authorization': `Bearer ${localStorage.getItem('authToken')}`
                }
            });
        }
    },

    // System APIs
    system: {
        healthCheck: () => apiService.request('/health'),
        getConfig: () => apiService.request('/system/config'),
        backupDatabase: () => apiService.request('/system/backup'),
        restoreDatabase: (backupId) => apiService.request(`/system/restore/${backupId}`)
    }
};

// Export the API service
window.apiService = apiService;

// Utility functions
const apiUtils = {
    // Format date for API
    formatDate(date) {
        return date.toISOString().split('T')[0];
    },

    // Get current academic year (Ghana system: Sept-Aug)
    getCurrentAcademicYear() {
        const now = new Date();
        const year = now.getFullYear();
        const month = now.getMonth() + 1;
        
        // Academic year runs from September to August
        if (month >= 9) {
            return `${year}/${year + 1}`;
        } else {
            return `${year - 1}/${year}`;
        }
    },

    // Get current term
    getCurrentTerm() {
        const month = new Date().getMonth() + 1;
        if (month >= 1 && month <= 4) return 'First Term';
        if (month >= 5 && month <= 8) return 'Second Term';
        return 'Third Term';
    },

    // Calculate grade from score
    calculateGrade(score) {
        if (score >= 80) return { grade: 'A1', remark: 'Excellent' };
        if (score >= 75) return { grade: 'B2', remark: 'Very Good' };
        if (score >= 70) return { grade: 'B3', remark: 'Good' };
        if (score >= 65) return { grade: 'C4', remark: 'Credit' };
        if (score >= 60) return { grade: 'C5', remark: 'Credit' };
        if (score >= 55) return { grade: 'C6', remark: 'Credit' };
        if (score >= 50) return { grade: 'D7', remark: 'Pass' };
        if (score >= 45) return { grade: 'D8', remark: 'Pass' };
        return { grade: 'F9', remark: 'Fail' };
    },

    // Calculate promotion status
    calculatePromotionStatus(averageScore, failedSubjects) {
        if (averageScore >= 50 && failedSubjects <= 2) {
            return 'Promoted';
        } else if (averageScore >= 40 && failedSubjects <= 3) {
            return 'Conditional';
        } else {
            return 'Repeat';
        }
    }
};

// Export utility functions
window.apiUtils = apiUtils;
